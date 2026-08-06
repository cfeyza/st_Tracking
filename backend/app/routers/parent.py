from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.deps import get_current_parent
from app.models.announcement import Announcement, announcement_classrooms
from app.models.classroom import classroom_students
from app.models.parent import ParentProfile, parent_students
from app.models.student import StudentProfile
from app.models.user import User
from app.schemas.announcement import ParentAnnouncementOut
from app.schemas.pagination import Page
from app.schemas.parent import ParentProfileOut, ParentStudentListItem, StudentCodeRequest

router = APIRouter(prefix="/parent", tags=["parent"])


@router.get("/me", response_model=ParentProfileOut)
async def get_me(
    parent: ParentProfile = Depends(get_current_parent),
    db: AsyncSession = Depends(get_db),
) -> ParentProfileOut:
    user = await db.get(User, parent.user_id)
    return ParentProfileOut(name=parent.name, surname=parent.surname, email=user.email)


@router.post("/student-code", status_code=status.HTTP_204_NO_CONTENT)
async def add_student_code(
    payload: StudentCodeRequest,
    parent: ParentProfile = Depends(get_current_parent),
    db: AsyncSession = Depends(get_db),
) -> None:
    result = await db.execute(select(StudentProfile).where(StudentProfile.student_code == payload.code.strip()))
    student = result.scalar_one_or_none()
    if student is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invalid student code")

    existing = await db.execute(
        select(parent_students).where(
            parent_students.c.parent_id == parent.id, parent_students.c.student_id == student.id
        )
    )
    if existing.first() is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="You are already linked to this student")

    await db.execute(parent_students.insert().values(parent_id=parent.id, student_id=student.id))
    await db.commit()


@router.get("/students", response_model=list[ParentStudentListItem])
async def list_students(
    parent: ParentProfile = Depends(get_current_parent),
    db: AsyncSession = Depends(get_db),
) -> list[ParentStudentListItem]:
    result = await db.execute(
        select(StudentProfile)
        .join(parent_students, parent_students.c.student_id == StudentProfile.id)
        .where(parent_students.c.parent_id == parent.id)
        .order_by(StudentProfile.surname, StudentProfile.name)
    )
    students = result.scalars().all()
    return [
        ParentStudentListItem(id=s.id, name=s.name, surname=s.surname, school_id=s.school_id) for s in students
    ]


@router.get("/announcements", response_model=Page[ParentAnnouncementOut])
async def list_announcements(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    parent: ParentProfile = Depends(get_current_parent),
    db: AsyncSession = Depends(get_db),
) -> Page[ParentAnnouncementOut]:
    parent_student_ids = select(parent_students.c.student_id).where(parent_students.c.parent_id == parent.id)

    pairs = (
        select(
            Announcement.id.label("announcement_id"),
            StudentProfile.id.label("student_id"),
            Announcement.created_at.label("created_at"),
        )
        .distinct()
        .select_from(Announcement)
        .join(announcement_classrooms, announcement_classrooms.c.announcement_id == Announcement.id)
        .join(classroom_students, classroom_students.c.classroom_id == announcement_classrooms.c.classroom_id)
        .join(StudentProfile, StudentProfile.id == classroom_students.c.student_id)
        .where(classroom_students.c.student_id.in_(parent_student_ids))
    ).subquery()

    total = await db.scalar(select(func.count()).select_from(pairs))

    rows = (
        await db.execute(
            select(pairs.c.announcement_id, pairs.c.student_id)
            .order_by(pairs.c.created_at.desc(), pairs.c.announcement_id, pairs.c.student_id)
            .limit(page_size)
            .offset((page - 1) * page_size)
        )
    ).all()

    if not rows:
        return Page.build(items=[], total=total or 0, page=page, page_size=page_size)

    announcement_ids = {row.announcement_id for row in rows}
    student_ids = {row.student_id for row in rows}

    announcements_result = await db.execute(
        select(Announcement)
        .options(selectinload(Announcement.classrooms), selectinload(Announcement.teacher))
        .where(Announcement.id.in_(announcement_ids))
    )
    announcements_by_id = {a.id: a for a in announcements_result.scalars().unique().all()}

    students_result = await db.execute(select(StudentProfile).where(StudentProfile.id.in_(student_ids)))
    students_by_id = {s.id: s for s in students_result.scalars().all()}

    items = [
        ParentAnnouncementOut(
            id=announcement.id,
            text=announcement.text,
            created_at=announcement.created_at,
            teacher_name=f"{announcement.teacher.name} {announcement.teacher.surname}",
            classrooms=[c.name for c in announcement.classrooms],
            student_name=f"{student.name} {student.surname}",
        )
        for row in rows
        for announcement in (announcements_by_id[row.announcement_id],)
        for student in (students_by_id[row.student_id],)
    ]

    return Page.build(items=items, total=total or 0, page=page, page_size=page_size)
