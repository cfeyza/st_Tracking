"""
Integration tests for app/routers/auth.py.

Covers: POST /auth/register, GET /auth/verify-email, POST /auth/login.

send_verification_email is patched to a no-op in every test (autouse fixture).
Individual tests that need it to fail use a local patch override.
"""

from datetime import datetime, timedelta, timezone
from unittest.mock import patch

import pytest
from httpx import AsyncClient
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile
from app.models.user import Role, User
from app.models.verification import EmailVerificationToken


# ── Helpers ───────────────────────────────────────────────────────────────────

def _teacher_payload(**overrides):
    return {
        "email": "teacher@example.com",
        "password": "SecurePass1!",
        "role": "teacher",
        "name": "Ali",
        "surname": "Demir",
        **overrides,
    }


def _student_payload(**overrides):
    return {
        "email": "student@example.com",
        "password": "SecurePass1!",
        "role": "student",
        "name": "Ahmet",
        "surname": "Yilmaz",
        "school_id": 12345,
        **overrides,
    }


def _parent_payload(**overrides):
    return {
        "email": "parent@example.com",
        "password": "SecurePass1!",
        "role": "parent",
        "name": "Anne",
        "surname": "Yilmaz",
        **overrides,
    }


# ── Autouse: suppress real email sending ─────────────────────────────────────

@pytest.fixture(autouse=True)
def _mock_email(monkeypatch):
    monkeypatch.setattr("app.routers.auth.send_verification_email", lambda **kw: None)


# ──────────────────────────────────────────────────────────────────────────────
# POST /auth/register
# ──────────────────────────────────────────────────────────────────────────────

class TestRegister:

    async def test_teacher_registration_returns_201(self, client: AsyncClient):
        resp = await client.post("/auth/register", json=_teacher_payload())
        assert resp.status_code == 201

    async def test_student_registration_returns_201(self, client: AsyncClient):
        resp = await client.post("/auth/register", json=_student_payload())
        assert resp.status_code == 201

    async def test_parent_registration_returns_201(self, client: AsyncClient):
        resp = await client.post("/auth/register", json=_parent_payload())
        assert resp.status_code == 201

    async def test_teacher_profile_created(self, client: AsyncClient, db: AsyncSession):
        await client.post("/auth/register", json=_teacher_payload())
        result = await db.execute(select(TeacherProfile))
        profiles = result.scalars().all()
        assert len(profiles) == 1
        assert profiles[0].name == "Ali"
        assert profiles[0].teacher_code.startswith("TCH-")

    async def test_student_profile_created_with_school_id(self, client: AsyncClient, db: AsyncSession):
        await client.post("/auth/register", json=_student_payload())
        result = await db.execute(select(StudentProfile).where(StudentProfile.user_id.is_not(None)))
        profiles = result.scalars().all()
        assert len(profiles) == 1
        assert profiles[0].school_id == 12345

    async def test_new_user_is_unverified(self, client: AsyncClient, db: AsyncSession):
        await client.post("/auth/register", json=_teacher_payload())
        result = await db.execute(select(User).where(User.email == "teacher@example.com"))
        user = result.scalar_one()
        assert user.is_verified is False

    async def test_verification_token_created(self, client: AsyncClient, db: AsyncSession):
        await client.post("/auth/register", json=_teacher_payload())
        result = await db.execute(select(User).where(User.email == "teacher@example.com"))
        user = result.scalar_one()
        token_result = await db.execute(
            select(EmailVerificationToken).where(EmailVerificationToken.user_id == user.id)
        )
        token = token_result.scalar_one_or_none()
        assert token is not None
        assert token.expires_at > datetime.now(timezone.utc)

    async def test_duplicate_verified_email_raises_409(self, client: AsyncClient, db: AsyncSession):
        # Manually create a verified user
        from app.core.security import hash_password
        user = User(
            email="teacher@example.com",
            password_hash=hash_password("irrelevant"),
            role=Role.TEACHER,
            is_verified=True,
        )
        db.add(user)
        await db.commit()

        resp = await client.post("/auth/register", json=_teacher_payload())
        assert resp.status_code == 409

    async def test_duplicate_unverified_email_with_active_token_raises_409(
        self, client: AsyncClient, db: AsyncSession
    ):
        from app.core.security import hash_password
        user = User(
            email="teacher@example.com",
            password_hash=hash_password("irrelevant"),
            role=Role.TEACHER,
            is_verified=False,
        )
        db.add(user)
        await db.flush()
        # Active token (expires in the future)
        db.add(EmailVerificationToken(
            user_id=user.id,
            token="still-valid-token",
            expires_at=datetime.now(timezone.utc) + timedelta(hours=24),
        ))
        await db.commit()

        resp = await client.post("/auth/register", json=_teacher_payload())
        assert resp.status_code == 409

    async def test_duplicate_unverified_email_with_expired_token_allows_reregister(
        self, client: AsyncClient, db: AsyncSession
    ):
        from app.core.security import hash_password
        user = User(
            email="teacher@example.com",
            password_hash=hash_password("irrelevant"),
            role=Role.TEACHER,
            is_verified=False,
        )
        db.add(user)
        await db.flush()
        # Expired token (1 hour in the past)
        db.add(EmailVerificationToken(
            user_id=user.id,
            token="expired-token",
            expires_at=datetime.now(timezone.utc) - timedelta(hours=1),
        ))
        await db.commit()

        resp = await client.post("/auth/register", json=_teacher_payload())
        assert resp.status_code == 201

        # Stale user should be gone; only the new registration remains
        result = await db.execute(select(User).where(User.email == "teacher@example.com"))
        users = result.scalars().all()
        assert len(users) == 1
        assert users[0].is_verified is False

    async def test_duplicate_student_school_id_raises_409(self, client: AsyncClient, db: AsyncSession):
        # Register first student
        await client.post("/auth/register", json=_student_payload())
        # Manually verify the first student so it counts as "registered"
        result = await db.execute(select(User).where(User.email == "student@example.com"))
        user = result.scalar_one()
        user.is_verified = True
        await db.commit()

        # Second student with same school_id
        resp = await client.post(
            "/auth/register",
            json=_student_payload(email="student2@example.com"),
        )
        assert resp.status_code == 409

    async def test_email_send_failure_returns_503(self, client: AsyncClient):
        with patch(
            "app.routers.auth.send_verification_email",
            side_effect=Exception("SMTP unreachable"),
        ):
            resp = await client.post("/auth/register", json=_teacher_payload())
        assert resp.status_code == 503


# ──────────────────────────────────────────────────────────────────────────────
# GET /auth/verify-email
# ──────────────────────────────────────────────────────────────────────────────

class TestVerifyEmail:

    async def _register_and_get_token(self, client, db) -> tuple[str, int]:
        await client.post("/auth/register", json=_teacher_payload())
        result = await db.execute(select(User).where(User.email == "teacher@example.com"))
        user = result.scalar_one()
        token_row = await db.execute(
            select(EmailVerificationToken).where(EmailVerificationToken.user_id == user.id)
        )
        token = token_row.scalar_one()
        return token.token, user.id

    async def test_valid_token_verifies_user(self, client: AsyncClient, db: AsyncSession):
        token_str, user_id = await self._register_and_get_token(client, db)

        resp = await client.get(f"/auth/verify-email?token={token_str}")
        assert resp.status_code == 200

        db.expire_all()  # sync method — marks in-memory objects as stale
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one()
        assert user.is_verified is True

    async def test_valid_token_is_deleted_after_use(self, client: AsyncClient, db: AsyncSession):
        token_str, user_id = await self._register_and_get_token(client, db)
        await client.get(f"/auth/verify-email?token={token_str}")

        result = await db.execute(
            select(EmailVerificationToken).where(EmailVerificationToken.user_id == user_id)
        )
        assert result.scalar_one_or_none() is None

    async def test_invalid_token_returns_400(self, client: AsyncClient):
        resp = await client.get("/auth/verify-email?token=does-not-exist")
        assert resp.status_code == 400

    async def test_expired_token_returns_400(self, client: AsyncClient, db: AsyncSession):
        from app.core.security import hash_password
        user = User(
            email="exp@example.com",
            password_hash=hash_password("irrelevant"),
            role=Role.TEACHER,
            is_verified=False,
        )
        db.add(user)
        await db.flush()
        db.add(EmailVerificationToken(
            user_id=user.id,
            token="my-expired-token",
            expires_at=datetime.now(timezone.utc) - timedelta(hours=1),
        ))
        await db.commit()

        resp = await client.get("/auth/verify-email?token=my-expired-token")
        assert resp.status_code == 400

    async def test_expired_token_is_deleted(self, client: AsyncClient, db: AsyncSession):
        from app.core.security import hash_password
        user = User(
            email="exp2@example.com",
            password_hash=hash_password("irrelevant"),
            role=Role.TEACHER,
            is_verified=False,
        )
        db.add(user)
        await db.flush()
        db.add(EmailVerificationToken(
            user_id=user.id,
            token="delete-me-expired",
            expires_at=datetime.now(timezone.utc) - timedelta(hours=1),
        ))
        await db.commit()

        await client.get("/auth/verify-email?token=delete-me-expired")

        result = await db.execute(
            select(EmailVerificationToken).where(EmailVerificationToken.user_id == user.id)
        )
        assert result.scalar_one_or_none() is None


# ──────────────────────────────────────────────────────────────────────────────
# POST /auth/login
# ──────────────────────────────────────────────────────────────────────────────

class TestLogin:

    async def _create_verified_teacher(self, db: AsyncSession, email="login@example.com", password="Pass1234!"):
        from app.core.security import hash_password
        from app.models.teacher import TeacherProfile
        user = User(
            email=email,
            password_hash=hash_password(password),
            role=Role.TEACHER,
            is_verified=True,
        )
        db.add(user)
        await db.flush()
        db.add(TeacherProfile(user_id=user.id, name="Test", surname="Teacher", teacher_code="TCH-LOGIN01"))
        await db.commit()
        return user

    async def test_valid_credentials_return_access_token(self, client: AsyncClient, db: AsyncSession):
        await self._create_verified_teacher(db)
        resp = await client.post("/auth/login", json={"email": "login@example.com", "password": "Pass1234!"})
        assert resp.status_code == 200
        body = resp.json()
        assert "access_token" in body
        assert body["role"] == "teacher"

    async def test_wrong_password_returns_401(self, client: AsyncClient, db: AsyncSession):
        await self._create_verified_teacher(db)
        resp = await client.post("/auth/login", json={"email": "login@example.com", "password": "WrongPass!"})
        assert resp.status_code == 401

    async def test_unknown_email_returns_401(self, client: AsyncClient):
        resp = await client.post("/auth/login", json={"email": "nobody@example.com", "password": "Pass1234!"})
        assert resp.status_code == 401

    async def test_unverified_user_returns_403(self, client: AsyncClient, db: AsyncSession):
        from app.core.security import hash_password
        user = User(
            email="unverified@example.com",
            password_hash=hash_password("Pass1234!"),
            role=Role.TEACHER,
            is_verified=False,
        )
        db.add(user)
        await db.commit()

        resp = await client.post("/auth/login", json={"email": "unverified@example.com", "password": "Pass1234!"})
        assert resp.status_code == 403

    async def test_access_token_is_decodable(self, client: AsyncClient, db: AsyncSession):
        await self._create_verified_teacher(db)
        resp = await client.post("/auth/login", json={"email": "login@example.com", "password": "Pass1234!"})
        token = resp.json()["access_token"]

        from app.core.security import decode_access_token
        payload = decode_access_token(token)
        assert payload is not None
        assert payload["role"] == "teacher"
