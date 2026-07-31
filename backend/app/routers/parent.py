from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.deps import get_current_parent
from app.models.announcement import Announcement
from app.models.classroom import Classroom, classroom_students
from app.models.parent import ParentProfile, parent_students
from app.models.student import StudentProfile
from app.models.user import User
from app.schemas.announcement import ParentAnnouncementOut
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


@router.get("/announcements", response_model=list[ParentAnnouncementOut])
async def list_announcements(
    parent: ParentProfile = Depends(get_current_parent),
    db: AsyncSession = Depends(get_db),
) -> list[ParentAnnouncementOut]:
    students_result = await db.execute(
        select(StudentProfile)
        .join(parent_students, parent_students.c.student_id == StudentProfile.id)
        .where(parent_students.c.parent_id == parent.id)
    )
    students = students_result.scalars().all()

    feed: list[ParentAnnouncementOut] = []
    for student in students:
        student_classroom_ids = select(classroom_students.c.classroom_id).where(
            classroom_students.c.student_id == student.id
        )
        announcements_result = await db.execute(
            select(Announcement)
            .options(selectinload(Announcement.classrooms), selectinload(Announcement.teacher))
            .where(Announcement.classrooms.any(Classroom.id.in_(student_classroom_ids)))
        )
        for announcement in announcements_result.scalars().unique().all():
            feed.append(
                ParentAnnouncementOut(
                    id=announcement.id,
                    text=announcement.text,
                    created_at=announcement.created_at,
                    teacher_name=f"{announcement.teacher.name} {announcement.teacher.surname}",
                    classrooms=[c.name for c in announcement.classrooms],
                    student_name=f"{student.name} {student.surname}",
                )
            )

    feed.sort(key=lambda item: item.created_at, reverse=True)
    return feed
