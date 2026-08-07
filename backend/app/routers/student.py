from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.constants import DEFAULT_PAGE_SIZE
from app.db.session import get_db
from app.deps import get_current_student
from app.models.announcement import Announcement, announcement_classrooms
from app.models.classroom import Classroom, classroom_students
from app.models.device_token import DeviceToken
from app.models.grade import Grade
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile
from app.models.user import User
from app.schemas.announcement import StudentAnnouncementOut
from app.schemas.pagination import Page
from app.schemas.device_token import DeviceTokenOut, DeviceTokenRegister
from app.schemas.grade import GradeOut
from app.schemas.student import StudentProfileOut, TeacherCodeRequest, TeacherCodeResponse, TeacherFilterItem
from app.services.roster import find_and_link_teacher_code

router = APIRouter(prefix="/student", tags=["student"])


@router.get("/me", response_model=StudentProfileOut)
async def get_me(
    student: StudentProfile = Depends(get_current_student),
    db: AsyncSession = Depends(get_db),
) -> StudentProfileOut:
    user = await db.get(User, student.user_id)
    return StudentProfileOut(
        id=student.id,
        student_code=student.student_code,
        name=student.name,
        surname=student.surname,
        school_id=student.school_id,
        email=user.email,
    )


@router.post("/device-token", response_model=DeviceTokenOut, status_code=status.HTTP_200_OK)
async def register_device_token(
    payload: DeviceTokenRegister,
    student: StudentProfile = Depends(get_current_student),
    db: AsyncSession = Depends(get_db),
) -> DeviceTokenOut:
    """Registers an FCM device token for push notifications. Upserts by
    token value: if this exact token is already registered (e.g. the same
    device was previously used by a different student, or this student is
    just logging in again), it's reassigned to the current student rather
    than inserted twice.
    """
    token = payload.token.strip()
    result = await db.execute(select(DeviceToken).where(DeviceToken.token == token))
    existing = result.scalar_one_or_none()
    if existing is not None:
        existing.student_id = student.id
        device_token = existing
    else:
        device_token = DeviceToken(student_id=student.id, token=token)
        db.add(device_token)

    await db.commit()
    await db.refresh(device_token)
    return DeviceTokenOut(id=device_token.id, token=device_token.token)


@router.post("/teacher-code", response_model=TeacherCodeResponse)
async def add_teacher_code(
    payload: TeacherCodeRequest,
    student: StudentProfile = Depends(get_current_student),
    db: AsyncSession = Depends(get_db),
) -> TeacherCodeResponse:
    """Redeems a teacher code. The teacher must have already imported this
    student into a classroom roster (matched by name, surname, and school
    ID) — this call finds that roster entry and links the student to
    whatever classroom(s) the teacher already placed them in.
    """
    result = await db.execute(select(TeacherProfile).where(TeacherProfile.teacher_code == payload.code.strip()))
    teacher = result.scalar_one_or_none()
    if teacher is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid teacher code")

    classrooms = await find_and_link_teacher_code(db, teacher, student)
    await db.commit()

    return TeacherCodeResponse(teacher_name=f"{teacher.name} {teacher.surname}", classrooms=classrooms)


@router.get("/announcement-teachers", response_model=list[TeacherFilterItem])
async def list_announcement_teachers(
    student: StudentProfile = Depends(get_current_student),
    db: AsyncSession = Depends(get_db),
) -> list[TeacherFilterItem]:
    result = await db.execute(
        select(TeacherProfile)
        .join(Announcement, Announcement.teacher_id == TeacherProfile.id)
        .join(announcement_classrooms, announcement_classrooms.c.announcement_id == Announcement.id)
        .join(classroom_students, classroom_students.c.classroom_id == announcement_classrooms.c.classroom_id)
        .where(classroom_students.c.student_id == student.id)
        .distinct()
        .order_by(TeacherProfile.name, TeacherProfile.surname)
    )
    teachers = result.scalars().unique().all()
    return [TeacherFilterItem(id=t.id, name=f"{t.name} {t.surname}") for t in teachers]


@router.get("/announcements", response_model=Page[StudentAnnouncementOut])
async def list_announcements(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=DEFAULT_PAGE_SIZE, ge=1, le=100),
    teacher_id: int | None = Query(default=None),
    student: StudentProfile = Depends(get_current_student),
    db: AsyncSession = Depends(get_db),
) -> Page[StudentAnnouncementOut]:
    my_classroom_ids = select(classroom_students.c.classroom_id).where(
        classroom_students.c.student_id == student.id
    )
    filters = [Announcement.classrooms.any(Classroom.id.in_(my_classroom_ids))]
    if teacher_id is not None:
        filters.append(Announcement.teacher_id == teacher_id)
    total = await db.scalar(
        select(func.count(Announcement.id)).where(*filters)
    )
    result = await db.execute(
        select(Announcement)
        .options(selectinload(Announcement.classrooms), selectinload(Announcement.teacher))
        .where(*filters)
        .order_by(Announcement.created_at.desc())
        .limit(page_size)
        .offset((page - 1) * page_size)
    )
    announcements = result.scalars().unique().all()
    items = [
        StudentAnnouncementOut(
            id=a.id,
            text=a.text,
            created_at=a.created_at,
            teacher_name=f"{a.teacher.name} {a.teacher.surname}",
            classrooms=[c.name for c in a.classrooms],
        )
        for a in announcements
    ]
    return Page.build(items=items, total=total or 0, page=page, page_size=page_size)


@router.get("/grades", response_model=list[GradeOut])
async def list_grades(
    student: StudentProfile = Depends(get_current_student),
    db: AsyncSession = Depends(get_db),
) -> list[GradeOut]:
    result = await db.execute(
        select(Grade)
        .options(selectinload(Grade.classroom), selectinload(Grade.teacher))
        .where(Grade.student_id == student.id)
        .order_by(Grade.created_at.desc())
    )
    grades = result.scalars().all()
    return [
        GradeOut(
            id=g.id,
            subject=g.subject,
            value=g.value,
            created_at=g.created_at,
            teacher_name=f"{g.teacher.name} {g.teacher.surname}",
            classroom_name=g.classroom.name if g.classroom else None,
            student_name=None,
        )
        for g in grades
    ]
