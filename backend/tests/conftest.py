"""
Shared test infrastructure for the student tracking backend.

Environment variables
---------------------
DATABASE_URL  – asyncpg URL for the test database (must point to a *test*
                database, not the production one — conftest drops and
                recreates all tables at session start).
                Default: postgresql+asyncpg://student_tracking_user:testpass
                         @localhost:5432/student_tracking_test
JWT_SECRET_KEY – any value other than the insecure default in config.py.
                 Set here so the Settings validator does not raise when the
                 module is first imported by pytest.

Firebase and SMTP are stubbed out at import time so no real credentials are
needed in the test environment.
"""

import os
import sys
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock

# ── 1. Env vars (must be set before any app.* import) ────────────────────────
# JWT_SECRET_KEY: only override when not already provided (local .env wins; CI
# sets this via workflow env var; the default here satisfies the validator in
# environments where neither is present).
os.environ.setdefault(
    "JWT_SECRET_KEY",
    "test-only-secret-key-do-not-use-in-production-" + "x" * 16,
)

# ── 2. Firebase stub (prevents credentials file lookups) ─────────────────────
_firebase_stub = MagicMock()
for _mod in ("firebase_admin", "firebase_admin.credentials", "firebase_admin.messaging"):
    sys.modules.setdefault(_mod, _firebase_stub)

# ── 3. App imports (safe now that env vars and stubs are in place) ────────────
import pytest
import pytest_asyncio
from httpx import ASGITransport, AsyncClient
from sqlalchemy import select, text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.pool import NullPool

import app.models  # noqa: F401 — registers every ORM class in Base.metadata
from app.core.config import settings
from app.core.security import hash_password
from app.db.base_class import Base
from app.db.session import get_db
from app.main import app
from app.models.classroom import Classroom, classroom_students
from app.models.grade import Grade
from app.models.parent import ParentProfile, parent_students
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile, teacher_students
from app.models.user import Role, User
from app.models.verification import EmailVerificationToken

# ── 4. Test database URL ──────────────────────────────────────────────────────
# Precedence: TEST_DATABASE_URL env var (set explicitly in CI) → automatic
# _test suffix derived from the project's own DATABASE_URL (local dev).
def _test_db_url() -> str:
    if explicit := os.environ.get("TEST_DATABASE_URL"):
        return explicit
    prod = settings.DATABASE_URL
    base, _, db = prod.rpartition("/")
    db_name = db.split("?")[0]
    suffix = "" if db_name.endswith("_test") else "_test"
    return f"{base}/{db_name}{suffix}"

_TEST_DB_URL = _test_db_url()
# NullPool: each checkout gets a brand-new connection that is closed immediately
# on return.  This prevents asyncpg from reusing a connection that was created
# in a different event loop (which would trigger "Future attached to a different
# loop" errors when pytest-asyncio gives each test its own loop).
_engine = create_async_engine(_TEST_DB_URL, echo=False, future=True, poolclass=NullPool)
_TestSession = async_sessionmaker(bind=_engine, expire_on_commit=False, class_=AsyncSession)


# ── 5. Schema lifecycle (once per pytest session) ─────────────────────────────
# Not autouse — only DB-backed fixtures pull this in, so PDF roster tests
# (which need no database) are never burdened with a DB connection.
@pytest_asyncio.fixture(scope="session")
async def _create_schema():
    async with _engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
        await conn.run_sync(Base.metadata.create_all)
    yield


# ── 6. Per-test isolation: truncate all tables after each test ────────────────
@pytest_asyncio.fixture
async def _clean_tables(_create_schema):
    yield
    async with _engine.begin() as conn:
        names = ", ".join(f'"{t.name}"' for t in Base.metadata.sorted_tables)
        await conn.execute(text(f"TRUNCATE {names} RESTART IDENTITY CASCADE"))


# ── 7. Rate-limiter: disabled for every test ──────────────────────────────────
@pytest.fixture(autouse=True)
def _no_rate_limits():
    from app.core.limiter import limiter
    limiter.enabled = False   # slowapi 0.1.9 uses .enabled (no underscore)
    yield
    limiter.enabled = True


# ── 8. Database session fixture ───────────────────────────────────────────────
@pytest_asyncio.fixture
async def db(_clean_tables):
    async with _TestSession() as session:
        yield session


# ── 9. FastAPI test client (wired to the test DB session) ─────────────────────
@pytest_asyncio.fixture
async def client(db):
    async def _override_get_db():
        yield db

    app.dependency_overrides[get_db] = _override_get_db
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


# ── 10. Common data fixtures ──────────────────────────────────────────────────

@pytest_asyncio.fixture
async def teacher(db: AsyncSession):
    """Returns (User, TeacherProfile) for a verified teacher account."""
    user = User(
        email="teacher@test.local",
        password_hash=hash_password("Pass1234!"),
        role=Role.TEACHER,
        is_verified=True,
    )
    db.add(user)
    await db.flush()
    profile = TeacherProfile(
        user_id=user.id, name="Ali", surname="Demir", teacher_code="TCH-TESTFIXTURE"
    )
    db.add(profile)
    await db.flush()
    return user, profile


@pytest_asyncio.fixture
async def classroom(db: AsyncSession, teacher):
    _, teacher_profile = teacher
    room = Classroom(teacher_id=teacher_profile.id, name="9A")
    db.add(room)
    await db.flush()
    return room


@pytest_asyncio.fixture
async def placeholder(db: AsyncSession, teacher, classroom):
    """A teacher-imported placeholder StudentProfile (no user account yet)."""
    _, teacher_profile = teacher
    student = StudentProfile(
        user_id=None,
        name="Ahmet",
        surname="Yilmaz",
        school_id=12345,
        student_code="STU-PLACEHOLDER",
    )
    db.add(student)
    await db.flush()
    await db.execute(teacher_students.insert().values(teacher_id=teacher_profile.id, student_id=student.id))
    await db.execute(classroom_students.insert().values(classroom_id=classroom.id, student_id=student.id))
    await db.flush()
    return student


@pytest_asyncio.fixture
async def real_student(db: AsyncSession):
    """A fully registered student whose name/school_id matches placeholder."""
    user = User(
        email="student@test.local",
        password_hash=hash_password("Pass1234!"),
        role=Role.STUDENT,
        is_verified=True,
    )
    db.add(user)
    await db.flush()
    profile = StudentProfile(
        user_id=user.id,
        name="Ahmet",
        surname="Yilmaz",
        school_id=12345,
        student_code="STU-REALSTUDENT",
    )
    db.add(profile)
    await db.flush()
    return user, profile
