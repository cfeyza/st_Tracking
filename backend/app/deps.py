from fastapi import Depends, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.db.session import get_db
from app.l10n import L10nHTTPException
from app.models.parent import ParentProfile
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile
from app.models.user import Role, User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    credentials_exception = L10nHTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        en="Could not validate credentials",
        tr="Kimlik bilgileri doğrulanamadı",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = decode_access_token(token)
    if payload is None or "sub" not in payload:
        raise credentials_exception

    try:
        user_id = int(payload["sub"])
    except (ValueError, TypeError):
        raise credentials_exception
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None:
        raise credentials_exception
    return user


async def get_current_teacher(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> TeacherProfile:
    if user.role != Role.TEACHER:
        raise L10nHTTPException(status_code=status.HTTP_403_FORBIDDEN, en="Teacher role required", tr="Bu işlem için öğretmen rolü gereklidir")
    result = await db.execute(
        select(TeacherProfile).where(TeacherProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise L10nHTTPException(status_code=status.HTTP_404_NOT_FOUND, en="Teacher profile not found", tr="Öğretmen profili bulunamadı")
    return profile


async def get_current_student(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> StudentProfile:
    if user.role != Role.STUDENT:
        raise L10nHTTPException(status_code=status.HTTP_403_FORBIDDEN, en="Student role required", tr="Bu işlem için öğrenci rolü gereklidir")
    result = await db.execute(
        select(StudentProfile).where(StudentProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise L10nHTTPException(status_code=status.HTTP_404_NOT_FOUND, en="Student profile not found", tr="Öğrenci profili bulunamadı")
    return profile


async def get_current_parent(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> ParentProfile:
    if user.role != Role.PARENT:
        raise L10nHTTPException(status_code=status.HTTP_403_FORBIDDEN, en="Parent role required", tr="Bu işlem için veli rolü gereklidir")
    result = await db.execute(
        select(ParentProfile).where(ParentProfile.user_id == user.id)
    )
    profile = result.scalar_one_or_none()
    if profile is None:
        raise L10nHTTPException(status_code=status.HTTP_404_NOT_FOUND, en="Parent profile not found", tr="Veli profili bulunamadı")
    return profile
