from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.deps import get_current_teacher
from app.models.announcement import Announcement
from app.models.classroom import Classroom, classroom_students
from app.models.grade import Grade
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile, teacher_students
from app.models.user import User
from app.schemas.announcement import AnnouncementCreate, AnnouncementOut
from app.schemas.classroom import ClassroomCreate, ClassroomOut, RosterImportRequest
from app.schemas.grade import GradeCreate, GradeOut
from app.schemas.pagination import Page
from app.schemas.teacher import StudentListItem, TeacherDashboardOut, TeacherProfileOut
from app.services.roster import RosterEntryInput, import_roster

router = APIRouter(prefix="/teacher", tags=["teacher"])


@router.get("/me", response_model=TeacherProfileOut)
async def get_me(
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> TeacherProfileOut:
    user = await db.get(User, teacher.user_id)
    return TeacherProfileOut(
        id=teacher.id, teacher_code=teacher.teacher_code, name=teacher.name, surname=teacher.surname, email=user.email
    )


@router.get("/dashboard", response_model=TeacherDashboardOut)
async def get_dashboard(
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> TeacherDashboardOut:
    classroom_count = await db.scalar(
        select(func.count()).select_from(Classroom).where(Classroom.teacher_id == teacher.id)
    )
    student_count = await db.scalar(
        select(func.count()).select_from(teacher_students).where(teacher_students.c.teacher_id == teacher.id)
    )
    return TeacherDashboardOut(classroom_count=classroom_count or 0, student_count=student_count or 0)


@router.post("/classrooms", response_model=ClassroomOut, status_code=status.HTTP_201_CREATED)
async def create_classroom(
    payload: ClassroomCreate,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> ClassroomOut:
    name = payload.name.strip()
    existing = await db.execute(
        select(Classroom).where(Classroom.teacher_id == teacher.id, func.lower(Classroom.name) == name.lower())
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"A classroom named '{name}' already exists. Pick it from the existing classrooms list instead.",
        )

    classroom = Classroom(teacher_id=teacher.id, name=name)
    db.add(classroom)
    await db.flush()

    students = []
    if payload.students:
        entries = [RosterEntryInput(name=s.name, surname=s.surname, school_id=s.school_id) for s in payload.students]
        students = await import_roster(db, teacher, classroom, entries)

    await db.commit()
    await db.refresh(classroom)
    return ClassroomOut(id=classroom.id, name=classroom.name, student_count=len(students), created_at=classroom.created_at)


@router.get("/classrooms", response_model=Page[ClassroomOut])
async def list_classrooms(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> Page[ClassroomOut]:
    total = await db.scalar(
        select(func.count()).select_from(Classroom).where(Classroom.teacher_id == teacher.id)
    )

    result = await db.execute(
        select(Classroom, func.count(classroom_students.c.student_id))
        .outerjoin(classroom_students, classroom_students.c.classroom_id == Classroom.id)
        .where(Classroom.teacher_id == teacher.id)
        .group_by(Classroom.id)
        .order_by(Classroom.name)
        .limit(page_size)
        .offset((page - 1) * page_size)
    )
    items = [
        ClassroomOut(id=classroom.id, name=classroom.name, student_count=count, created_at=classroom.created_at)
        for classroom, count in result.all()
    ]
    return Page.build(items=items, total=total or 0, page=page, page_size=page_size)


async def _get_owned_classroom(db: AsyncSession, teacher_id: int, classroom_id: int) -> Classroom:
    classroom = await db.get(Classroom, classroom_id)
    if classroom is None or classroom.teacher_id != teacher_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Classroom not found")
    return classroom


@router.delete("/classrooms/{classroom_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_classroom(
    classroom_id: int,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Deletes the classroom and its roster links. Any student left with no
    other classroom under this teacher is also unlinked from the teacher's
    roster (teacher_students) — same as delete_student, just automatic. The
    StudentProfile row, grade history, and other teachers'/parents' links
    stay intact.
    """
    classroom = await _get_owned_classroom(db, teacher.id, classroom_id)

    student_ids = (
        await db.execute(
            select(classroom_students.c.student_id).where(classroom_students.c.classroom_id == classroom_id)
        )
    ).scalars().all()

    await db.delete(classroom)
    await db.flush()

    if student_ids:
        still_enrolled = (
            await db.execute(
                select(classroom_students.c.student_id)
                .join(Classroom, Classroom.id == classroom_students.c.classroom_id)
                .where(Classroom.teacher_id == teacher.id, classroom_students.c.student_id.in_(student_ids))
            )
        ).scalars().all()
        orphaned_ids = set(student_ids) - set(still_enrolled)
        if orphaned_ids:
            await db.execute(
                teacher_students.delete().where(
                    teacher_students.c.teacher_id == teacher.id,
                    teacher_students.c.student_id.in_(orphaned_ids),
                )
            )

    await db.commit()


@router.post("/classrooms/{classroom_id}/roster", response_model=list[StudentListItem], status_code=status.HTTP_201_CREATED)
async def add_to_roster(
    classroom_id: int,
    payload: RosterImportRequest,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> list[StudentListItem]:
    """Add students to a classroom by name/surname/school_id — manual entry.
    The teacher never needs to separately place these students into the
    right classroom; the roster import does that in one step. Each row must
    be a genuinely new student — a school_id that already belongs to a
    student this teacher knows, or to a different registered account, is
    rejected (see import_roster).
    """
    classroom = await _get_owned_classroom(db, teacher.id, classroom_id)
    entries = [RosterEntryInput(name=s.name, surname=s.surname, school_id=s.school_id) for s in payload.students]
    students = await import_roster(db, teacher, classroom, entries)
    await db.commit()

    return [
        StudentListItem(
            id=s.id,
            name=s.name,
            surname=s.surname,
            school_id=s.school_id,
            student_code=s.student_code,
            classrooms=[classroom.name],
            is_registered=s.user_id is not None,
        )
        for s in students
    ]


@router.post("/classrooms/{classroom_id}/roster/pdf", status_code=status.HTTP_501_NOT_IMPLEMENTED)
async def import_roster_pdf(
    classroom_id: int,
    file: UploadFile,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Placeholder for PDF roster import. Not implemented yet — use
    POST /teacher/classrooms/{classroom_id}/roster for manual entry.
    """
    await _get_owned_classroom(db, teacher.id, classroom_id)
    raise HTTPException(
        status_code=status.HTTP_501_NOT_IMPLEMENTED,
        detail="PDF roster import isn't implemented yet. Please use manual roster entry for now.",
    )


@router.delete("/classrooms/{classroom_id}/students/{student_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unenroll_student(
    classroom_id: int,
    student_id: int,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> None:
    classroom = await _get_owned_classroom(db, teacher.id, classroom_id)
    result = await db.execute(
        select(StudentProfile).options(selectinload(StudentProfile.classrooms)).where(StudentProfile.id == student_id)
    )
    student = result.scalar_one_or_none()
    if student is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
    if classroom in student.classrooms:
        student.classrooms.remove(classroom)
    await db.commit()


SortField = Literal["classroom", "name", "surname", "school_id"]
SortOrder = Literal["asc", "desc"]


@router.get("/students", response_model=Page[StudentListItem])
async def list_students(
    classroom_id: int | None = Query(default=None),
    sort_by: SortField = Query(default="surname"),
    order: SortOrder = Query(default="asc"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=20, ge=1, le=100),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> Page[StudentListItem]:
    classrooms_agg = (
        select(
            classroom_students.c.student_id.label("student_id"),
            func.string_agg(Classroom.name, ", ").label("classroom_names"),
        )
        .select_from(classroom_students.join(Classroom, Classroom.id == classroom_students.c.classroom_id))
        .where(Classroom.teacher_id == teacher.id)
        .group_by(classroom_students.c.student_id)
        .subquery()
    )

    query = (
        select(StudentProfile, classrooms_agg.c.classroom_names)
        .join(teacher_students, teacher_students.c.student_id == StudentProfile.id)
        .outerjoin(classrooms_agg, classrooms_agg.c.student_id == StudentProfile.id)
        .where(teacher_students.c.teacher_id == teacher.id)
    )

    if classroom_id is not None:
        query = query.where(
            StudentProfile.id.in_(
                select(classroom_students.c.student_id).where(classroom_students.c.classroom_id == classroom_id)
            )
        )

    total = await db.scalar(select(func.count()).select_from(query.subquery()))

    sort_column = {
        "classroom": classrooms_agg.c.classroom_names,
        "name": StudentProfile.name,
        "surname": StudentProfile.surname,
        "school_id": StudentProfile.school_id,
    }[sort_by]
    query = query.order_by(sort_column.desc() if order == "desc" else sort_column.asc())
    query = query.limit(page_size).offset((page - 1) * page_size)

    result = await db.execute(query)
    items = []
    for student, classroom_names in result.all():
        items.append(
            StudentListItem(
                id=student.id,
                name=student.name,
                surname=student.surname,
                school_id=student.school_id,
                student_code=student.student_code,
                classrooms=classroom_names.split(", ") if classroom_names else [],
                is_registered=student.user_id is not None,
            )
        )
    return Page.build(items=items, total=total or 0, page=page, page_size=page_size)


@router.delete("/students/{student_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_student(
    student_id: int,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Unlinks a student from this teacher entirely: removed from every
    classroom this teacher owns, and from this teacher's roster. The
    StudentProfile row itself (and any other teacher/parent links) is left
    intact, and past grades stay in history.
    """
    link = await db.execute(
        select(teacher_students).where(
            teacher_students.c.teacher_id == teacher.id, teacher_students.c.student_id == student_id
        )
    )
    if link.first() is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

    owned_classroom_ids = select(Classroom.id).where(Classroom.teacher_id == teacher.id)
    await db.execute(
        classroom_students.delete().where(
            classroom_students.c.student_id == student_id,
            classroom_students.c.classroom_id.in_(owned_classroom_ids),
        )
    )
    await db.execute(
        teacher_students.delete().where(
            teacher_students.c.teacher_id == teacher.id, teacher_students.c.student_id == student_id
        )
    )
    await db.commit()


@router.post("/announcements", response_model=AnnouncementOut, status_code=status.HTTP_201_CREATED)
async def create_announcement(
    payload: AnnouncementCreate,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> AnnouncementOut:
    if not payload.classroom_ids:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="At least one target classroom is required")

    result = await db.execute(
        select(Classroom).where(Classroom.id.in_(payload.classroom_ids), Classroom.teacher_id == teacher.id)
    )
    classrooms = result.scalars().all()
    if len(classrooms) != len(set(payload.classroom_ids)):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="One or more classrooms are invalid")

    announcement = Announcement(teacher_id=teacher.id, text=payload.text.strip(), classrooms=classrooms)
    db.add(announcement)
    await db.commit()
    await db.refresh(announcement)

    return AnnouncementOut(
        id=announcement.id,
        text=announcement.text,
        created_at=announcement.created_at,
        classrooms=[c.name for c in classrooms],
    )


@router.get("/announcements", response_model=list[AnnouncementOut])
async def list_announcements(
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> list[AnnouncementOut]:
    result = await db.execute(
        select(Announcement)
        .options(selectinload(Announcement.classrooms))
        .where(Announcement.teacher_id == teacher.id)
        .order_by(Announcement.created_at.desc())
    )
    announcements = result.scalars().all()
    return [
        AnnouncementOut(
            id=a.id, text=a.text, created_at=a.created_at, classrooms=[c.name for c in a.classrooms]
        )
        for a in announcements
    ]


@router.post("/grades", response_model=GradeOut, status_code=status.HTTP_201_CREATED)
async def add_grade(
    payload: GradeCreate,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> GradeOut:
    link = await db.execute(
        select(teacher_students).where(
            teacher_students.c.teacher_id == teacher.id, teacher_students.c.student_id == payload.student_id
        )
    )
    if link.first() is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This student is not linked to you")

    classroom_name: str | None = None
    if payload.classroom_id is not None:
        classroom = await _get_owned_classroom(db, teacher.id, payload.classroom_id)
        classroom_name = classroom.name

    student = await db.get(StudentProfile, payload.student_id)

    grade = Grade(
        teacher_id=teacher.id,
        student_id=payload.student_id,
        classroom_id=payload.classroom_id,
        subject=payload.subject.strip(),
        value=payload.value.strip(),
    )
    db.add(grade)
    await db.commit()
    await db.refresh(grade)

    return GradeOut(
        id=grade.id,
        subject=grade.subject,
        value=grade.value,
        created_at=grade.created_at,
        teacher_name=f"{teacher.name} {teacher.surname}",
        classroom_name=classroom_name,
        student_name=f"{student.name} {student.surname}",
    )


@router.get("/grades", response_model=list[GradeOut])
async def list_grades(
    student_id: int | None = Query(default=None),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> list[GradeOut]:
    query = (
        select(Grade)
        .options(selectinload(Grade.classroom), selectinload(Grade.student))
        .where(Grade.teacher_id == teacher.id)
        .order_by(Grade.created_at.desc())
    )
    if student_id is not None:
        query = query.where(Grade.student_id == student_id)

    result = await db.execute(query)
    grades = result.scalars().all()
    return [
        GradeOut(
            id=g.id,
            subject=g.subject,
            value=g.value,
            created_at=g.created_at,
            teacher_name=f"{teacher.name} {teacher.surname}",
            classroom_name=g.classroom.name if g.classroom else None,
            student_name=f"{g.student.name} {g.student.surname}",
        )
        for g in grades
    ]
