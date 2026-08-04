from dataclasses import dataclass

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.dialects.postgresql import insert as pg_insert
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import generate_unique_code
from app.models.classroom import Classroom, classroom_students
from app.models.grade import Grade
from app.models.parent import parent_students
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile, teacher_students


@dataclass
class RosterEntryInput:
    name: str
    surname: str
    school_id: int


async def _generate_student_code(db: AsyncSession) -> str:
    for _ in range(10):
        code = generate_unique_code("STU")
        result = await db.execute(select(StudentProfile).where(StudentProfile.student_code == code))
        if result.scalar_one_or_none() is None:
            return code
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Could not generate a unique code")


async def import_roster(
    db: AsyncSession,
    teacher: TeacherProfile,
    classroom: Classroom,
    entries: list[RosterEntryInput],
) -> list[StudentProfile]:
    """Adds each roster row to the classroom as a brand new placeholder
    StudentProfile (no user account yet).

    This is allowed even if the school_id already belongs to a registered
    student account elsewhere: a matching name and school_id is not proof
    that the registered account actually belongs to this teacher's class —
    across many schools, teachers, and students, that collision is expected
    and cannot be resolved automatically. The placeholder and the registered
    account stay separate, independent rows until the student proves the
    relationship by redeeming this teacher's code (see
    find_and_link_teacher_code), which is the only thing that merges them.

    A school_id this teacher already has on their own roster is rejected
    with 409 — that part is safe to check automatically since it only looks
    at this teacher's own existing roster.
    """
    result_profiles: list[StudentProfile] = []

    for entry in entries:
        school_id = entry.school_id
        name = entry.name.strip()
        surname = entry.surname.strip()

        existing = await db.execute(
            select(StudentProfile)
            .join(teacher_students, teacher_students.c.student_id == StudentProfile.id)
            .where(teacher_students.c.teacher_id == teacher.id, StudentProfile.school_id == school_id)
        )
        if existing.scalars().first() is not None:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"A student with school ID '{school_id}' already exists in your roster.",
            )

        student = StudentProfile(
            user_id=None,
            name=name,
            surname=surname,
            school_id=school_id,
            student_code=await _generate_student_code(db),
        )
        db.add(student)
        await db.flush()
        await db.execute(teacher_students.insert().values(teacher_id=teacher.id, student_id=student.id))

        await db.execute(
            pg_insert(classroom_students)
            .values(classroom_id=classroom.id, student_id=student.id)
            .on_conflict_do_nothing()
        )

        result_profiles.append(student)

    return result_profiles


async def find_and_link_teacher_code(
    db: AsyncSession,
    teacher: TeacherProfile,
    student: StudentProfile,
) -> list[str]:
    """Matches a newly-registered student against a placeholder the teacher
    already imported (by name + surname + school_id), merges the
    placeholder's classroom/parent/grade history onto the real StudentProfile
    row, links the teacher to the real row, and discards the placeholder.
    Returns the classroom names the student now belongs to under this
    teacher. Raises 404 if no matching roster row is found.
    """
    already_linked = await db.execute(
        select(teacher_students).where(
            teacher_students.c.teacher_id == teacher.id, teacher_students.c.student_id == student.id
        )
    )
    if already_linked.first() is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="You are already linked to this teacher")

    candidates = await db.execute(
        select(StudentProfile)
        .options(selectinload(StudentProfile.classrooms), selectinload(StudentProfile.grades))
        .join(teacher_students, teacher_students.c.student_id == StudentProfile.id)
        .where(
            teacher_students.c.teacher_id == teacher.id,
            StudentProfile.user_id.is_(None),
            func.lower(StudentProfile.name) == student.name.lower(),
            func.lower(StudentProfile.surname) == student.surname.lower(),
            StudentProfile.school_id == student.school_id,
        )
    )
    matches = candidates.scalars().unique().all()

    if not matches:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                "No matching student record found for this teacher. "
                "Ask your teacher to add you to a classroom roster first."
            ),
        )
    if len(matches) > 1:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Multiple matching roster records were found for this teacher. Please contact support.",
        )

    placeholder = matches[0]

    # Move classroom memberships onto the real account (skip ones it's
    # somehow already in).
    placeholder_classroom_ids = await db.execute(
        select(classroom_students.c.classroom_id).where(classroom_students.c.student_id == placeholder.id)
    )
    for (classroom_id,) in placeholder_classroom_ids.all():
        await db.execute(
            pg_insert(classroom_students)
            .values(classroom_id=classroom_id, student_id=student.id)
            .on_conflict_do_nothing()
        )

    # Move any parents who linked to the placeholder before this student
    # registered onto the real account.
    placeholder_parent_ids = await db.execute(
        select(parent_students.c.parent_id).where(parent_students.c.student_id == placeholder.id)
    )
    for (parent_id,) in placeholder_parent_ids.all():
        await db.execute(
            pg_insert(parent_students).values(parent_id=parent_id, student_id=student.id).on_conflict_do_nothing()
        )

    # Grades have their own surrogate primary key, so a plain reassignment is safe.
    await db.execute(Grade.__table__.update().where(Grade.student_id == placeholder.id).values(student_id=student.id))

    await db.execute(teacher_students.insert().values(teacher_id=teacher.id, student_id=student.id))

    await db.delete(placeholder)
    await db.flush()

    classrooms_result = await db.execute(
        select(Classroom.name)
        .join(classroom_students, classroom_students.c.classroom_id == Classroom.id)
        .where(classroom_students.c.student_id == student.id, Classroom.teacher_id == teacher.id)
    )
    return [row[0] for row in classrooms_result.all()]
