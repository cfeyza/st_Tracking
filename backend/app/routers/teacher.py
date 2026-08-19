from datetime import datetime, timezone
from typing import Literal

from fastapi import APIRouter, BackgroundTasks, Depends, Query, UploadFile, status
from starlette.concurrency import run_in_threadpool
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.constants import DEFAULT_PAGE_SIZE
from app.db.session import get_db
from app.deps import get_current_teacher
from app.l10n import L10nHTTPException
from app.models.announcement import Announcement, AnnouncementRead, announcement_classrooms
from app.models.classroom import Classroom, classroom_students
from app.models.grade import Grade
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile, teacher_students
from app.models.user import User
from app.schemas.announcement import AnnouncementCreate, AnnouncementOut, AnnouncementReadersOut, StudentReaderInfo
from app.schemas.classroom import (
    ClassroomCreate,
    ClassroomOut,
    PdfImportClassroomResult,
    PdfImportResult,
    PdfPreviewEntry,
    PdfPreviewPage,
    PdfPreviewResult,
    RosterImportRequest,
)
from app.schemas.grade import GradeCreate, GradeOut
from app.schemas.pagination import Page
from app.schemas.teacher import StudentListItem, TeacherDashboardOut, TeacherProfileOut
from app.services.pdf_roster import OcrUnavailableError, parse_pdf
from app.services.push import send_announcement_push
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
        select(func.count()).select_from(Classroom).where(
            Classroom.teacher_id == teacher.id, Classroom.deleted_at.is_(None)
        )
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
        select(Classroom).where(
            Classroom.teacher_id == teacher.id,
            func.lower(Classroom.name) == name.lower(),
            Classroom.deleted_at.is_(None),
        )
    )
    if existing.scalar_one_or_none() is not None:
        raise L10nHTTPException(
            status_code=status.HTTP_409_CONFLICT,
            en=f"A classroom named '{name}' already exists. Pick it from the existing classrooms list instead.",
            tr=f"'{name}' adında bir sınıf zaten var. Bunun yerine mevcut sınıflar listesinden seçin.",
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
    page_size: int = Query(default=DEFAULT_PAGE_SIZE, ge=1, le=100),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> Page[ClassroomOut]:
    total = await db.scalar(
        select(func.count()).select_from(Classroom).where(
            Classroom.teacher_id == teacher.id, Classroom.deleted_at.is_(None)
        )
    )

    result = await db.execute(
        select(Classroom, func.count(classroom_students.c.student_id))
        .outerjoin(classroom_students, classroom_students.c.classroom_id == Classroom.id)
        .where(Classroom.teacher_id == teacher.id, Classroom.deleted_at.is_(None))
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
    if classroom is None or classroom.teacher_id != teacher_id or classroom.deleted_at is not None:
        raise L10nHTTPException(status_code=status.HTTP_404_NOT_FOUND, en="Classroom not found", tr="Sınıf bulunamadı")
    return classroom


@router.delete("/classrooms/{classroom_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_classroom(
    classroom_id: int,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> None:
    """Soft-deletes the classroom by stamping deleted_at.

    classroom_students links and grades.classroom_id are kept intact so the
    delete is reversible. Queries that list active classrooms already filter
    on Classroom.deleted_at.is_(None), so the links become invisible without
    being destroyed. Only teacher_students is cleaned up for students who are
    no longer enrolled in any of this teacher's active classrooms.
    """
    classroom = await _get_owned_classroom(db, teacher.id, classroom_id)

    student_ids = (
        await db.execute(
            select(classroom_students.c.student_id).where(classroom_students.c.classroom_id == classroom_id)
        )
    ).scalars().all()

    classroom.deleted_at = datetime.now(timezone.utc)

    await db.flush()

    if student_ids:
        still_enrolled = (
            await db.execute(
                select(classroom_students.c.student_id)
                .join(Classroom, Classroom.id == classroom_students.c.classroom_id)
                .where(
                    Classroom.teacher_id == teacher.id,
                    Classroom.deleted_at.is_(None),
                    classroom_students.c.student_id.in_(student_ids),
                )
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
    right classroom; the roster import does that in one step. Each row
    becomes its own placeholder student, even if a registered account
    already exists with the same school_id elsewhere — the app can't verify
    that account actually belongs to this teacher's class, so it never links
    automatically (see import_roster). Only a school_id already on this
    teacher's own roster is rejected.
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


async def _find_duplicate_school_ids(db: AsyncSession, teacher_id: int, school_ids: list[int]) -> set[int]:
    if not school_ids:
        return set()
    result = await db.execute(
        select(StudentProfile.school_id)
        .join(teacher_students, teacher_students.c.student_id == StudentProfile.id)
        .where(teacher_students.c.teacher_id == teacher_id, StudentProfile.school_id.in_(school_ids))
    )
    return set(result.scalars().all())


@router.post("/classrooms/import/pdf", response_model=PdfImportResult, status_code=status.HTTP_200_OK)
async def import_classrooms_pdf(
    file: UploadFile,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> PdfImportResult:
    """Parses an e-Okul style class-list PDF (see app/services/pdf_roster.py)
    and bulk-creates/updates one classroom per detected page title, reusing
    import_roster for the actual student creation. A page that can't be read
    (no title found, no table found, OCR unavailable) is reported in
    `errors` without affecting the other pages. A school_id already on this
    teacher's roster — whether from before this upload or from an earlier
    page in the same PDF — is skipped rather than rejected outright, since
    one bad row shouldn't cost the rest of a multi-page scan.
    """
    filename = file.filename or ""
    if not filename.lower().endswith(".pdf"):
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="Please upload a PDF file.", tr="Lütfen bir PDF dosyası yükleyin.")

    _MAX_PDF_BYTES = 20 * 1024 * 1024  # 20 MB
    file_bytes = await file.read(_MAX_PDF_BYTES + 1)
    if len(file_bytes) > _MAX_PDF_BYTES:
        raise L10nHTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, en="PDF must be 20 MB or smaller.", tr="PDF 20 MB veya daha küçük olmalıdır.")
    try:
        pages = await run_in_threadpool(parse_pdf, file_bytes)
    except OcrUnavailableError as exc:
        raise L10nHTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, en=str(exc), tr="Bu sunucuda OCR (Tesseract) kullanılamıyor. Lütfen yönetici ile iletişime geçin.") from exc
    except Exception as exc:
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="Could not read this file as a PDF.", tr="Bu dosya PDF olarak okunamadı.") from exc

    classroom_results: dict[int, PdfImportClassroomResult] = {}
    errors: list[str] = []
    seen_school_ids: set[int] = set()

    all_page_school_ids = [
        entry.school_id
        for page in pages
        if not page.error and page.classroom_name is not None
        for entry in page.entries
    ]
    existing_school_ids = await _find_duplicate_school_ids(db, teacher.id, all_page_school_ids)

    for page in pages:
        if page.error:
            errors.append(f"Page {page.page_number}: {page.error}")
            continue
        if page.classroom_name is None:
            errors.append(f"Page {page.page_number}: could not detect a classroom title.")
            continue

        existing = await db.execute(
            select(Classroom).where(
                Classroom.teacher_id == teacher.id,
                func.lower(Classroom.name) == page.classroom_name.lower(),
                Classroom.deleted_at.is_(None),
            )
        )
        classroom = existing.scalar_one_or_none()
        created_classroom = classroom is None
        if classroom is None:
            classroom = Classroom(teacher_id=teacher.id, name=page.classroom_name)
            db.add(classroom)
            await db.flush()

        skipped: list[str] = []
        clean_entries = []
        for entry in page.entries:
            school_id = entry.school_id
            if school_id in existing_school_ids or school_id in seen_school_ids:
                skipped.append(f"{school_id} ({entry.name} {entry.surname}): already in your roster")
                continue
            seen_school_ids.add(school_id)
            clean_entries.append(entry)

        students = await import_roster(db, teacher, classroom, clean_entries) if clean_entries else []

        if classroom.id in classroom_results:
            existing_result = classroom_results[classroom.id]
            existing_result.students_added += len(students)
            existing_result.skipped.extend(skipped)
            existing_result.warnings.extend(page.warnings)
        else:
            classroom_results[classroom.id] = PdfImportClassroomResult(
                classroom_id=classroom.id,
                classroom_name=classroom.name,
                created_classroom=created_classroom,
                students_added=len(students),
                skipped=skipped,
                warnings=list(page.warnings),
            )

    await db.commit()
    return PdfImportResult(classrooms=list(classroom_results.values()), errors=errors)


@router.post("/classrooms/import/pdf/preview", response_model=PdfPreviewResult, status_code=status.HTTP_200_OK)
async def preview_classrooms_pdf(
    file: UploadFile,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> PdfPreviewResult:
    """Parses an e-Okul PDF and returns what would be imported without writing
    anything to the database. Use this to verify OCR accuracy before committing.
    Each page shows its detected classroom name, the student rows that were
    read, which school_ids already exist in the teacher's roster, any rows
    that were skipped due to unreadable OCR output, and any page-level error.
    """
    filename = file.filename or ""
    if not filename.lower().endswith(".pdf"):
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="Please upload a PDF file.", tr="Lütfen bir PDF dosyası yükleyin.")

    _MAX_PDF_BYTES = 20 * 1024 * 1024
    file_bytes = await file.read(_MAX_PDF_BYTES + 1)
    if len(file_bytes) > _MAX_PDF_BYTES:
        raise L10nHTTPException(status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE, en="PDF must be 20 MB or smaller.", tr="PDF 20 MB veya daha küçük olmalıdır.")

    try:
        pages = await run_in_threadpool(parse_pdf, file_bytes)
    except OcrUnavailableError as exc:
        raise L10nHTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE, en=str(exc), tr="Bu sunucuda OCR (Tesseract) kullanılamıyor. Lütfen yönetici ile iletişime geçin.") from exc
    except Exception as exc:
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="Could not read this file as a PDF.", tr="Bu dosya PDF olarak okunamadı.") from exc

    all_school_ids = [e.school_id for p in pages if not p.error for e in p.entries]
    existing_ids = await _find_duplicate_school_ids(db, teacher.id, all_school_ids)

    preview_pages: list[PdfPreviewPage] = []
    for page in pages:
        entries = [
            PdfPreviewEntry(
                name=e.name,
                surname=e.surname,
                school_id=e.school_id,
                already_in_roster=e.school_id in existing_ids,
            )
            for e in page.entries
        ]
        preview_pages.append(
            PdfPreviewPage(
                page_number=page.page_number,
                classroom_name=page.classroom_name,
                entries=entries,
                warnings=page.warnings,
                error=page.error,
            )
        )

    return PdfPreviewResult(pages=preview_pages)


SortField = Literal["classroom", "name", "surname", "school_id"]
SortOrder = Literal["asc", "desc"]


@router.get("/students", response_model=Page[StudentListItem])
async def list_students(
    classroom_id: int | None = Query(default=None),
    sort_by: SortField = Query(default="classroom"),
    order: SortOrder = Query(default="asc"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=DEFAULT_PAGE_SIZE, ge=1, le=100),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> Page[StudentListItem]:
    classrooms_agg = (
        select(
            classroom_students.c.student_id.label("student_id"),
            func.array_agg(Classroom.name).label("classroom_names"),
        )
        .select_from(classroom_students.join(Classroom, Classroom.id == classroom_students.c.classroom_id))
        .where(Classroom.teacher_id == teacher.id, Classroom.deleted_at.is_(None))
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
        await _get_owned_classroom(db, teacher.id, classroom_id)
        query = query.where(
            StudentProfile.id.in_(
                select(classroom_students.c.student_id).where(classroom_students.c.classroom_id == classroom_id)
            )
        )

    count_query = (
        select(func.count(StudentProfile.id))
        .join(teacher_students, teacher_students.c.student_id == StudentProfile.id)
        .where(teacher_students.c.teacher_id == teacher.id)
    )
    if classroom_id is not None:
        count_query = count_query.where(
            StudentProfile.id.in_(
                select(classroom_students.c.student_id).where(classroom_students.c.classroom_id == classroom_id)
            )
        )
    total = await db.scalar(count_query)

    sort_columns = {
        "classroom": (classrooms_agg.c.classroom_names, StudentProfile.school_id),
        "name": (StudentProfile.name,),
        "surname": (StudentProfile.surname,),
        "school_id": (StudentProfile.school_id,),
    }[sort_by]
    query = query.order_by(*(c.desc() if order == "desc" else c.asc() for c in sort_columns))
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
                classrooms=classroom_names if classroom_names else [],
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
        raise L10nHTTPException(status_code=status.HTTP_404_NOT_FOUND, en="Student not found", tr="Öğrenci bulunamadı")

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
    background_tasks: BackgroundTasks,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> AnnouncementOut:
    if not payload.classroom_ids:
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="At least one target classroom is required", tr="En az bir hedef sınıf gereklidir")

    result = await db.execute(
        select(Classroom).where(
            Classroom.id.in_(payload.classroom_ids),
            Classroom.teacher_id == teacher.id,
            Classroom.deleted_at.is_(None),
        )
    )
    classrooms = result.scalars().all()
    if len(classrooms) != len(set(payload.classroom_ids)):
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="One or more classrooms are invalid", tr="Bir veya daha fazla sınıf geçersiz")

    announcement = Announcement(teacher_id=teacher.id, text=payload.text.strip(), classrooms=classrooms)
    db.add(announcement)
    await db.commit()
    await db.refresh(announcement)

    background_tasks.add_task(
        send_announcement_push,
        [c.id for c in classrooms],
        title=f"{teacher.name} {teacher.surname}",
        body=announcement.text[:180] + ("..." if len(announcement.text) > 180 else ""),
    )

    return AnnouncementOut(
        id=announcement.id,
        text=announcement.text,
        created_at=announcement.created_at,
        classrooms=[c.name for c in classrooms],
    )


@router.delete("/announcements/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_announcement(
    announcement_id: int,
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> None:
    result = await db.execute(
        select(Announcement).where(
            Announcement.id == announcement_id,
            Announcement.teacher_id == teacher.id,
            Announcement.deleted_at.is_(None),
        )
    )
    announcement = result.scalar_one_or_none()
    if announcement is None:
        raise L10nHTTPException(status_code=status.HTTP_404_NOT_FOUND, en="Announcement not found", tr="Duyuru bulunamadı")
    announcement.deleted_at = datetime.now(timezone.utc)
    await db.commit()


@router.get("/announcements/{announcement_id}/readers", response_model=AnnouncementReadersOut)
async def get_announcement_readers(
    announcement_id: int,
    filter_by: Literal["readers", "non_readers"] = Query(default="non_readers", alias="filter"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=DEFAULT_PAGE_SIZE, ge=1, le=100),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> AnnouncementReadersOut:
    """Returns a paginated read/unread list for the announcement's target classrooms.

    Use ?filter=readers for students who have read it, ?filter=non_readers (default)
    for those who haven't. Both totals are always included so the UI can show a summary.
    """
    announcement = await db.scalar(
        select(Announcement).where(
            Announcement.id == announcement_id,
            Announcement.teacher_id == teacher.id,
            Announcement.deleted_at.is_(None),
        )
    )
    if announcement is None:
        raise L10nHTTPException(status_code=status.HTTP_404_NOT_FOUND, en="Announcement not found", tr="Duyuru bulunamadı")

    read_join = (AnnouncementRead.student_id == StudentProfile.id) & (AnnouncementRead.announcement_id == announcement_id)

    total_readers = await db.scalar(
        select(func.count(func.distinct(StudentProfile.id)))
        .join(classroom_students, classroom_students.c.student_id == StudentProfile.id)
        .join(announcement_classrooms, announcement_classrooms.c.classroom_id == classroom_students.c.classroom_id)
        .join(AnnouncementRead, read_join)
        .where(announcement_classrooms.c.announcement_id == announcement_id)
    ) or 0

    total_non_readers = await db.scalar(
        select(func.count(func.distinct(StudentProfile.id)))
        .join(classroom_students, classroom_students.c.student_id == StudentProfile.id)
        .join(announcement_classrooms, announcement_classrooms.c.classroom_id == classroom_students.c.classroom_id)
        .outerjoin(AnnouncementRead, read_join)
        .where(announcement_classrooms.c.announcement_id == announcement_id)
        .where(AnnouncementRead.student_id.is_(None))
    ) or 0

    total = total_readers if filter_by == "readers" else total_non_readers
    total_pages = (total + page_size - 1) // page_size if page_size else 0

    if filter_by == "readers":
        rows = await db.execute(
            select(StudentProfile.id, StudentProfile.name, StudentProfile.surname, AnnouncementRead.read_at)
            .join(classroom_students, classroom_students.c.student_id == StudentProfile.id)
            .join(announcement_classrooms, announcement_classrooms.c.classroom_id == classroom_students.c.classroom_id)
            .join(AnnouncementRead, read_join)
            .where(announcement_classrooms.c.announcement_id == announcement_id)
            .distinct()
            .order_by(StudentProfile.surname, StudentProfile.name)
            .limit(page_size)
            .offset((page - 1) * page_size)
        )
        items = [StudentReaderInfo(id=r.id, name=r.name, surname=r.surname, read_at=r.read_at) for r in rows]
    else:
        rows = await db.execute(
            select(StudentProfile.id, StudentProfile.name, StudentProfile.surname)
            .join(classroom_students, classroom_students.c.student_id == StudentProfile.id)
            .join(announcement_classrooms, announcement_classrooms.c.classroom_id == classroom_students.c.classroom_id)
            .outerjoin(AnnouncementRead, read_join)
            .where(announcement_classrooms.c.announcement_id == announcement_id)
            .where(AnnouncementRead.student_id.is_(None))
            .distinct()
            .order_by(StudentProfile.surname, StudentProfile.name)
            .limit(page_size)
            .offset((page - 1) * page_size)
        )
        items = [StudentReaderInfo(id=r.id, name=r.name, surname=r.surname) for r in rows]

    return AnnouncementReadersOut(
        announcement_id=announcement_id,
        total_readers=total_readers,
        total_non_readers=total_non_readers,
        items=items,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )


@router.get("/announcements", response_model=Page[AnnouncementOut])
async def list_announcements(
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=DEFAULT_PAGE_SIZE, ge=1, le=100),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> Page[AnnouncementOut]:
    total = await db.scalar(
        select(func.count(Announcement.id)).where(
            Announcement.teacher_id == teacher.id, Announcement.deleted_at.is_(None)
        )
    )
    result = await db.execute(
        select(Announcement)
        .options(selectinload(Announcement.classrooms))
        .where(Announcement.teacher_id == teacher.id, Announcement.deleted_at.is_(None))
        .order_by(Announcement.created_at.desc())
        .limit(page_size)
        .offset((page - 1) * page_size)
    )
    announcements = result.scalars().all()
    items = [
        AnnouncementOut(id=a.id, text=a.text, created_at=a.created_at, classrooms=[c.name for c in a.classrooms])
        for a in announcements
    ]
    return Page.build(items=items, total=total or 0, page=page, page_size=page_size)


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
        raise L10nHTTPException(status_code=status.HTTP_400_BAD_REQUEST, en="This student is not linked to you", tr="Bu öğrenci size bağlı değil")

    classroom_name: str | None = None
    if payload.classroom_id is not None:
        classroom = await _get_owned_classroom(db, teacher.id, payload.classroom_id)
        classroom_name = classroom.name

        membership = await db.execute(
            select(classroom_students).where(
                classroom_students.c.classroom_id == payload.classroom_id,
                classroom_students.c.student_id == payload.student_id,
            )
        )
        if membership.first() is None:
            raise L10nHTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                en="Student not found in the specified classroom.",
                tr="Öğrenci belirtilen sınıfta bulunamadı.",
            )

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


GradeSortField = Literal["student", "subject", "value", "classroom", "date"]


@router.get("/grades", response_model=Page[GradeOut])
async def list_grades(
    student_id: int | None = Query(default=None),
    classroom_id: int | None = Query(default=None),
    sort_by: GradeSortField = Query(default="date"),
    order: SortOrder = Query(default="desc"),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=DEFAULT_PAGE_SIZE, ge=1, le=100),
    teacher: TeacherProfile = Depends(get_current_teacher),
    db: AsyncSession = Depends(get_db),
) -> Page[GradeOut]:
    query = (
        select(Grade)
        .join(StudentProfile, StudentProfile.id == Grade.student_id)
        .outerjoin(Classroom, Classroom.id == Grade.classroom_id)
        .options(selectinload(Grade.classroom), selectinload(Grade.student))
        .where(Grade.teacher_id == teacher.id)
    )
    if student_id is not None:
        query = query.where(Grade.student_id == student_id)
    if classroom_id is not None:
        await _get_owned_classroom(db, teacher.id, classroom_id)
        query = query.where(Grade.classroom_id == classroom_id)

    count_query = select(func.count(Grade.id)).where(Grade.teacher_id == teacher.id)
    if student_id is not None:
        count_query = count_query.where(Grade.student_id == student_id)
    if classroom_id is not None:
        count_query = count_query.where(Grade.classroom_id == classroom_id)
    total = await db.scalar(count_query)

    sort_columns = {
        "student": (StudentProfile.surname, StudentProfile.name),
        "subject": (Grade.subject,),
        "value": (Grade.value,),
        "classroom": (Classroom.name,),
        "date": (Grade.created_at,),
    }[sort_by]
    query = query.order_by(*(c.desc() if order == "desc" else c.asc() for c in sort_columns))
    query = query.limit(page_size).offset((page - 1) * page_size)

    result = await db.execute(query)
    grades = result.scalars().unique().all()
    items = [
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
    return Page.build(items=items, total=total or 0, page=page, page_size=page_size)
