import logging

import firebase_admin
from firebase_admin import credentials, messaging
from sqlalchemy import select

from app.core.config import settings
from app.db.session import AsyncSessionLocal
from app.models.classroom import classroom_students
from app.models.device_token import DeviceToken

logger = logging.getLogger("app.push")

_firebase_app: firebase_admin.App | None = None


def _get_firebase_app() -> firebase_admin.App:
    global _firebase_app
    if _firebase_app is None:
        cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
        _firebase_app = firebase_admin.initialize_app(cred)
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
            messages = [
                messaging.Message(notification=messaging.Notification(title=title, body=body), token=token)
                for token in tokens
            ]
            response = messaging.send_each(messages, app=app)

            invalid_tokens = [
                tokens[i]
                for i, r in enumerate(response.responses)
                if not r.success and isinstance(r.exception, messaging.UnregisteredError)
            ]
            if invalid_tokens:
                await db.execute(DeviceToken.__table__.delete().where(DeviceToken.token.in_(invalid_tokens)))
                await db.commit()

            logger.info(
                "Announcement push sent: %d succeeded, %d failed (classrooms=%s)",
                response.success_count,
                response.failure_count,
                classroom_ids,
            )
    except Exception:
        logger.exception("Failed to send announcement push notifications")
