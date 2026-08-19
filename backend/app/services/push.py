import logging

import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy import select
from starlette.concurrency import run_in_threadpool

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.models.classroom import classroom_students
from app.models.device_token import DeviceToken

logger = logging.getLogger("app.push")

_firebase_app: firebase_admin.App | None = None
_firebase_disabled = False


def _get_firebase_app() -> firebase_admin.App | None:
    global _firebase_app, _firebase_disabled
    if _firebase_disabled:
        return None
    if _firebase_app is None:
        try:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            _firebase_app = firebase_admin.initialize_app(cred)
        except Exception:
            logger.critical(
                "FCM disabled: failed to initialize Firebase from %r — push notifications will not be sent",
                settings.FIREBASE_CREDENTIALS_PATH,
                exc_info=True,
            )
            _firebase_disabled = True
            return None
    return _firebase_app


async def send_announcement_push(classroom_ids: list[int], title: str, body: str) -> None:
    """Fire-and-forget push send, run as a FastAPI BackgroundTask after an
    announcement has already been committed and the response sent. Opens its
    own DB session (the request's session is closed by the time a
    BackgroundTask runs) and must never raise, since there's no client left
    to receive an error.
    """
    try:
        async with AsyncSessionLocal() as db:
            result = await db.execute(
                select(classroom_students.c.student_id.distinct()).where(
                    classroom_students.c.classroom_id.in_(classroom_ids)
                )
            )
            student_ids = list(result.scalars().all())
            if not student_ids:
                return

            result = await db.execute(select(DeviceToken.token).where(DeviceToken.student_id.in_(student_ids)))
            tokens = list(result.scalars().all())
            if not tokens:
                return

            app = _get_firebase_app()
            if app is None:
                return
            messages = [
                messaging.Message(notification=messaging.Notification(title=title, body=body), token=token)
                for token in tokens
            ]

            # FCM per-response error types (firebase-admin 6.x):
            #   UnregisteredError   – token invalid/app uninstalled; safe to delete from DB
            #   QuotaExceededError  – project-level send rate exceeded; increase quota in
            #                         Firebase Console or reduce send volume
            #   SenderIdMismatchError – wrong Firebase project; indicates misconfiguration
            #   ThirdPartyAuthError – APNs cert/web-push key invalid
            # send_each() replaced deprecated send_all() in firebase-admin ≥6.x.
            BATCH_SIZE = 500
            total_success = 0
            total_failure = 0
            invalid_tokens: list[str] = []
            quota_failures = 0

            for batch_start in range(0, len(messages), BATCH_SIZE):
                batch_msgs = messages[batch_start : batch_start + BATCH_SIZE]
                batch_tokens = tokens[batch_start : batch_start + BATCH_SIZE]
                response = await run_in_threadpool(messaging.send_each, batch_msgs, app=app)
                total_success += response.success_count
                total_failure += response.failure_count
                for i, r in enumerate(response.responses):
                    if r.success:
                        continue
                    if isinstance(r.exception, messaging.UnregisteredError):
                        invalid_tokens.append(batch_tokens[i])
                    elif isinstance(r.exception, messaging.QuotaExceededError):
                        quota_failures += 1

            if quota_failures:
                logger.warning(
                    "FCM quota exceeded for %d message(s) — check Firebase Console send limits (classrooms=%s)",
                    quota_failures,
                    classroom_ids,
                )

            if invalid_tokens:
                await db.execute(DeviceToken.__table__.delete().where(DeviceToken.token.in_(invalid_tokens)))
                await db.commit()

            logger.info(
                "Announcement push sent: %d succeeded, %d failed (classrooms=%s)",
                total_success,
                total_failure,
                classroom_ids,
            )
    except Exception:
        logger.exception("Failed to send announcement push notifications")
