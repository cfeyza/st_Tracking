from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.deps import get_current_student
from app.models.announcement import Announcement
from app.models.classroom import Classroom, classroom_students
from app.models.grade import Grade
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile
from app.models.user import User
from app.schemas.announcement import StudentAnnouncementOut
from app.schemas.grade import GradeOut
from app.schemas.student import StudentProfileOut, TeacherCodeRequest, TeacherCodeResponse
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


@router.get("/announcements", response_model=list[StudentAnnouncementOut])
async def list_announcements(
    student: StudentProfile = Depends(get_current_student),
    db: AsyncSession = Depends(get_db),
) -> list[StudentAnnouncementOut]:
    my_classroom_ids = select(classroom_students.c.classroom_id).where(
        classroom_students.c.student_id == student.id
    )

    result = await db.execute(
        select(Announcement)
        .options(selectinload(Announcement.classrooms), selectinload(Announcement.teacher))
        .where(Announcement.classrooms.any(Classroom.id.in_(my_classroom_ids)))
        .order_by(Announcement.created_at.desc())
    )
    announcements = result.scalars().unique().all()

    return [
        StudentAnnouncementOut(
            id=a.id,
            text=a.text,
            created_at=a.created_at,
            teacher_name=f"{a.teacher.name} {a.teacher.surname}",
            classrooms=[c.name for c in a.classrooms],
        )
        for a in announcements
    ]


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
