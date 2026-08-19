"""
Tests for app/services/roster.py.

import_roster      — creates placeholder StudentProfile rows, wires them to the
                     teacher's roster and the target classroom.
find_and_link_teacher_code — matches a registered student against a teacher's
                     placeholder by name+surname+school_id, merges classroom
                     memberships / grades / parent links onto the real row, and
                     deletes the placeholder.
"""

import pytest
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.classroom import classroom_students
from app.models.grade import Grade
from app.models.parent import ParentProfile, parent_students
from app.models.student import StudentProfile
from app.models.teacher import TeacherProfile, teacher_students
from app.models.user import Role, User
from app.services.roster import RosterEntryInput, find_and_link_teacher_code, import_roster


# ──────────────────────────────────────────────────────────────────────────────
# import_roster
# ──────────────────────────────────────────────────────────────────────────────

class TestImportRoster:

    async def test_creates_placeholder_students(self, db: AsyncSession, teacher, classroom):
        _, t = teacher
        entries = [
            RosterEntryInput(name="Fatma", surname="Kaya", school_id=11111),
            RosterEntryInput(name="Mehmet", surname="Oz", school_id=22222),
        ]
        students = await import_roster(db, t, classroom, entries)

        assert len(students) == 2
        # All must be placeholders (no user account yet)
        for s in students:
            assert s.user_id is None
        assert {s.school_id for s in students} == {11111, 22222}

    async def test_assigns_to_teacher_roster(self, db: AsyncSession, teacher, classroom):
        _, t = teacher
        entries = [RosterEntryInput(name="Zeynep", surname="Celik", school_id=33333)]
        students = await import_roster(db, t, classroom, entries)

        result = await db.execute(
            select(teacher_students).where(
                teacher_students.c.teacher_id == t.id,
                teacher_students.c.student_id == students[0].id,
            )
        )
        assert result.first() is not None

    async def test_assigns_to_classroom(self, db: AsyncSession, teacher, classroom):
        _, t = teacher
        entries = [RosterEntryInput(name="Can", surname="Aydin", school_id=44444)]
        students = await import_roster(db, t, classroom, entries)

        result = await db.execute(
            select(classroom_students).where(
                classroom_students.c.classroom_id == classroom.id,
                classroom_students.c.student_id == students[0].id,
            )
        )
        assert result.first() is not None

    async def test_duplicate_school_id_within_batch_raises_409(self, db: AsyncSession, teacher, classroom):
        _, t = teacher
        entries = [
            RosterEntryInput(name="Ali", surname="X", school_id=55555),
            RosterEntryInput(name="Veli", surname="Y", school_id=55555),  # duplicate
        ]
        with pytest.raises(HTTPException) as exc_info:
            await import_roster(db, t, classroom, entries)
        assert exc_info.value.status_code == 409

    async def test_duplicate_school_id_already_on_roster_raises_409(
        self, db: AsyncSession, teacher, classroom, placeholder
    ):
        # placeholder has school_id=12345; try to import the same school_id again
        _, t = teacher
        entries = [RosterEntryInput(name="Someone", surname="Else", school_id=12345)]
        with pytest.raises(HTTPException) as exc_info:
            await import_roster(db, t, classroom, entries)
        assert exc_info.value.status_code == 409

    async def test_student_codes_are_unique(self, db: AsyncSession, teacher, classroom):
        _, t = teacher
        entries = [
            RosterEntryInput(name=f"Student{i}", surname="Test", school_id=70000 + i)
            for i in range(5)
        ]
        students = await import_roster(db, t, classroom, entries)
        codes = [s.student_code for s in students]
        assert len(codes) == len(set(codes))


# ──────────────────────────────────────────────────────────────────────────────
# find_and_link_teacher_code
# ──────────────────────────────────────────────────────────────────────────────

class TestFindAndLinkTeacherCode:

    async def test_happy_path_links_student_to_teacher(
        self, db: AsyncSession, teacher, classroom, placeholder, real_student
    ):
        _, t = teacher
        _, student = real_student
        await find_and_link_teacher_code(db, t, student)

        result = await db.execute(
            select(teacher_students).where(
                teacher_students.c.teacher_id == t.id,
                teacher_students.c.student_id == student.id,
            )
        )
        assert result.first() is not None

    async def test_placeholder_is_deleted_after_link(
        self, db: AsyncSession, teacher, classroom, placeholder, real_student
    ):
        _, t = teacher
        placeholder_id = placeholder.id
        _, student = real_student
        await find_and_link_teacher_code(db, t, student)
        await db.flush()

        result = await db.execute(
            select(StudentProfile).where(StudentProfile.id == placeholder_id)
        )
        assert result.scalar_one_or_none() is None

    async def test_migrates_classroom_membership(
        self, db: AsyncSession, teacher, classroom, placeholder, real_student
    ):
        _, t = teacher
        _, student = real_student
        classrooms_returned = await find_and_link_teacher_code(db, t, student)

        # Real student should now be in the classroom
        result = await db.execute(
            select(classroom_students).where(
                classroom_students.c.classroom_id == classroom.id,
                classroom_students.c.student_id == student.id,
            )
        )
        assert result.first() is not None
        assert "9A" in classrooms_returned

    async def test_migrates_grade_records(
        self, db: AsyncSession, teacher, classroom, placeholder, real_student
    ):
        _, t = teacher
        grade = Grade(
            teacher_id=t.id,
            student_id=placeholder.id,
            classroom_id=classroom.id,
            subject="Matematik",
            value="85",
        )
        db.add(grade)
        await db.flush()
        grade_id = grade.id

        _, student = real_student
        await find_and_link_teacher_code(db, t, student)
        await db.flush()

        result = await db.execute(select(Grade).where(Grade.id == grade_id))
        migrated = result.scalar_one()
        assert migrated.student_id == student.id

    async def test_migrates_parent_links(
        self, db: AsyncSession, teacher, classroom, placeholder, real_student
    ):
        # Create a parent linked to the placeholder
        parent_user = User(
            email="parent@test.local",
            password_hash="x",
            role=Role.PARENT,
            is_verified=True,
        )
        db.add(parent_user)
        await db.flush()
        parent = ParentProfile(user_id=parent_user.id, name="Anne", surname="Yilmaz")
        db.add(parent)
        await db.flush()
        await db.execute(parent_students.insert().values(parent_id=parent.id, student_id=placeholder.id))
        await db.flush()

        _, t = teacher
        _, student = real_student
        await find_and_link_teacher_code(db, t, student)
        await db.flush()

        result = await db.execute(
            select(parent_students).where(
                parent_students.c.parent_id == parent.id,
                parent_students.c.student_id == student.id,
            )
        )
        assert result.first() is not None

    async def test_no_matching_placeholder_raises_404(
        self, db: AsyncSession, teacher, real_student
    ):
        # No placeholder imported for this teacher → should 404
        _, t = teacher
        _, student = real_student
        with pytest.raises(HTTPException) as exc_info:
            await find_and_link_teacher_code(db, t, student)
        assert exc_info.value.status_code == 404

    async def test_already_linked_raises_409(
        self, db: AsyncSession, teacher, classroom, placeholder, real_student
    ):
        _, t = teacher
        _, student = real_student
        await find_and_link_teacher_code(db, t, student)
        await db.flush()

        # Second call: student is now linked, no placeholder left → 409
        with pytest.raises(HTTPException) as exc_info:
            await find_and_link_teacher_code(db, t, student)
        assert exc_info.value.status_code == 409

    async def test_name_mismatch_raises_404(self, db: AsyncSession, teacher, classroom, placeholder):
        # Register a student with a different name
        wrong_user = User(
            email="wrong@test.local",
            password_hash="x",
            role=Role.STUDENT,
            is_verified=True,
        )
        db.add(wrong_user)
        await db.flush()
        wrong_student = StudentProfile(
            user_id=wrong_user.id,
            name="Fatma",           # placeholder has "Ahmet"
            surname="Yilmaz",
            school_id=12345,
            student_code="STU-WRONGNAME",
        )
        db.add(wrong_student)
        await db.flush()

        _, t = teacher
        with pytest.raises(HTTPException) as exc_info:
            await find_and_link_teacher_code(db, t, wrong_student)
        assert exc_info.value.status_code == 404

    async def test_school_id_mismatch_raises_404(self, db: AsyncSession, teacher, classroom, placeholder):
        wrong_user = User(
            email="wrong2@test.local",
            password_hash="x",
            role=Role.STUDENT,
            is_verified=True,
        )
        db.add(wrong_user)
        await db.flush()
        wrong_student = StudentProfile(
            user_id=wrong_user.id,
            name="Ahmet",
            surname="Yilmaz",
            school_id=99999,        # placeholder has 12345
            student_code="STU-WRONGID",
        )
        db.add(wrong_student)
        await db.flush()

        _, t = teacher
        with pytest.raises(HTTPException) as exc_info:
            await find_and_link_teacher_code(db, t, wrong_student)
        assert exc_info.value.status_code == 404
