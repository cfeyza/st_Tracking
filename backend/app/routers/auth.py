from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Request, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.limiter import limiter
from app.core.security import (
    create_access_token,
    generate_unique_code,
    generate_verification_token,
    hash_password,
    verify_password,
)
from app.db.session import get_db
from app.l10n import L10nHTTPException
from app.models.parent import ParentProfile
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile
from app.models.user import Role, User
from app.models.verification import EmailVerificationToken
from app.schemas.auth import LoginRequest, LoginResponse, RegisterRequest, RegisterResponse, VerifyEmailResponse
from app.services.email import send_verification_email

router = APIRouter(prefix="/auth", tags=["auth"])


async def _unique_code(db: AsyncSession, model, column_name: str, prefix: str) -> str:
    column = getattr(model, column_name)
    for _ in range(10):
        code = generate_unique_code(prefix)
        result = await db.execute(select(model).where(column == code))
        if result.scalar_one_or_none() is None:
            return code
    raise L10nHTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, en="Could not generate a unique code", tr="Benzersiz kod oluşturulamadı")


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
@limiter.limit("10/minute")
async def register(request: Request, payload: RegisterRequest, db: AsyncSession = Depends(get_db)) -> RegisterResponse:
    existing = await db.execute(select(User).where(User.email == payload.email))
    existing_user = existing.scalar_one_or_none()
    if existing_user is not None:
        if existing_user.is_verified:
            raise L10nHTTPException(
                status_code=status.HTTP_409_CONFLICT,
                en="This email is already registered.",
                tr="Bu e-posta adresi zaten kayıtlı.",
            )

        token_result = await db.execute(
            select(EmailVerificationToken).where(EmailVerificationToken.user_id == existing_user.id)
        )
        existing_token = token_result.scalar_one_or_none()
        if existing_token is not None and existing_token.expires_at >= datetime.now(timezone.utc):
            raise L10nHTTPException(
                status_code=status.HTTP_409_CONFLICT,
                en="This email is already registered.",
                tr="Bu e-posta adresi zaten kayıtlı.",
            )

        # Unverified user with an expired (or missing) token: the old
        # registration is stale, so clear it out and let them register fresh.
        await db.delete(existing_user)
        await db.flush()

    if payload.role == Role.STUDENT:
        existing_school_id = await db.execute(
            select(StudentProfile).where(
                StudentProfile.school_id == payload.school_id,
                StudentProfile.user_id.is_not(None),
            )
        )
        if existing_school_id.scalar_one_or_none() is not None:
            raise L10nHTTPException(
                status_code=status.HTTP_409_CONFLICT,
                en="This school ID is already registered to another account.",
                tr="Bu okul numarası başka bir hesaba kayıtlı.",
            )

    user = User(
        email=payload.email,
        password_hash=hash_password(payload.password),
        role=payload.role,
        is_verified=False,
    )
    db.add(user)
    await db.flush()

    if payload.role == Role.TEACHER:
        code = await _unique_code(db, TeacherProfile, "teacher_code", "TCH")
        db.add(TeacherProfile(user_id=user.id, name=payload.name, surname=payload.surname, teacher_code=code))
    elif payload.role == Role.STUDENT:
        code = await _unique_code(db, StudentProfile, "student_code", "STU")
        db.add(
            StudentProfile(
                user_id=user.id,
                name=payload.name,
                surname=payload.surname,
                school_id=payload.school_id,
                student_code=code,
            )
        )
    else:
        db.add(ParentProfile(user_id=user.id, name=payload.name, surname=payload.surname))

    token = generate_verification_token()
    expires_at = datetime.now(timezone.utc) + timedelta(hours=settings.EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS)
    db.add(EmailVerificationToken(user_id=user.id, token=token, expires_at=expires_at))

    try:
        send_verification_email(to_email=payload.email, name=payload.name, token=token)
    except Exception:
        raise L10nHTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            en="We could not send a verification email right now. Please try again later.",
            tr="Şu anda doğrulama e-postası gönderilemedi. Lütfen daha sonra tekrar deneyin.",
        )

    await db.commit()
    return RegisterResponse()


@router.get("/verify-email", response_model=VerifyEmailResponse)
async def verify_email(token: str, db: AsyncSession = Depends(get_db)) -> VerifyEmailResponse:
    result = await db.execute(select(EmailVerificationToken).where(EmailVerificationToken.token == token))
    verification = result.scalar_one_or_none()

    if verification is None:
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="Invalid or already used verification link", tr="Geçersiz veya daha önce kullanılmış doğrulama bağlantısı")

    if verification.expires_at < datetime.now(timezone.utc):
        await db.delete(verification)
        await db.commit()
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="This verification link has expired", tr="Bu doğrulama bağlantısının süresi dolmuş")

    user_result = await db.execute(select(User).where(User.id == verification.user_id))
    user = user_result.scalar_one()
    user.is_verified = True

    await db.execute(
        EmailVerificationToken.__table__.delete().where(EmailVerificationToken.user_id == user.id)
    )
    await db.commit()

    return VerifyEmailResponse(message="Your email has been verified. You can now log in.")


@router.post("/login", response_model=LoginResponse)
@limiter.limit("5/minute")
async def login(request: Request, payload: LoginRequest, db: AsyncSession = Depends(get_db)) -> LoginResponse:
    result = await db.execute(select(User).where(User.email == payload.email))
    user = result.scalar_one_or_none()

    if user is None or not verify_password(payload.password, user.password_hash):
        raise L10nHTTPException(status_code=status.HTTP_401_UNAUTHORIZED, en="Incorrect email or password", tr="E-posta veya şifre hatalı")

    if not user.is_verified:
        raise L10nHTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            en="Please verify your email before logging in. Check your inbox for the verification link.",
            tr="Giriş yapmadan önce e-postanızı doğrulayın. Gelen kutunuzda doğrulama bağlantısını kontrol edin.",
        )

    access_token = create_access_token(subject=str(user.id), role=user.role.value)
    return LoginResponse(access_token=access_token, role=user.role)