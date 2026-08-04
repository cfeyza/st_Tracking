# Teacher grades page, PDF import, numeric school_id, default sorting

## Summary

Add a "Grades" page for teachers reached via a drawer button with three add-grade options (manual entry, plus two disabled placeholders), require picking a classroom before choosing a student in manual entry, import a class roster from a PDF, store `school_id` as an integer so it sorts numerically, and default student listing to sort by classroom then school_id.

## Prompt

○ Add a "Grades" page for teachers where the drawer's Add Grades button leads to three options (Enter Manually, Scan Optics, and Read Exam Sheet), with the latter two disabled (grayed out), and in the manual entry flow require selecting a classroom first so the student dropdown only shows students from the selected classroom.

○ PDF import: Add a PDF import feature that reads classroom information from the title (e.g. 9A) and imports each student's school_id, first name, and last name from the class list PDF, then bulk creates the students in the corresponding classroom.

○ school_id data type: Store `school_id` as an appropriate numeric data type instead of a string so it sorts numerically.

○ Default sorting: Make the default sorting by classroom and, within each classroom, by `school_id`.

## Response

1. Add-grades options screen (`frontend/lib/screens/teacher/teacher_add_grade_options_screen.dart`, new file)
   The drawer's "Add grades" action now opens this screen instead of going straight to manual entry. It lists three tiles: "Enter manually" (navigates to `/teacher/add-grade`), and "Scan optic form" / "Read exam sheet", both rendered disabled (grayed icon/text, no chevron, no `onTap`) with a "Coming soon" subtitle. Wired into `frontend/lib/main.dart` (`/teacher/add-grade-options` route) and `frontend/lib/screens/teacher/teacher_home_screen.dart` (drawer button now points at the new route).

2. Classroom-first manual entry (`frontend/lib/screens/teacher/teacher_add_grade_screen.dart`)
   Previously loaded all students and all classrooms up front, with an optional classroom filter. Now only classrooms load initially; the student dropdown is disabled ("Select a classroom first") until a classroom is picked, then lazily fetches that classroom's students (`TeacherService.listStudents(classroomId: ...)`) and resets the selected student whenever the classroom changes.

3. PDF class-roster import (`backend/app/services/pdf_roster.py`, `backend/app/routers/teacher.py`, `backend/app/schemas/classroom.py`, `frontend/lib/screens/teacher/teacher_add_classroom_screen.dart`, `frontend/lib/models/classroom.dart`, `frontend/lib/services/teacher_service.dart`)
   New `POST /teacher/classrooms/import/pdf` parses an uploaded e-Okul style PDF, detects each page's classroom title (e.g. "9. Sınıf / A Şubesi" → "9A"), and reads `school_id`/name/surname rows via OCR, then bulk-creates students per classroom through the existing `import_roster` service. Duplicate school IDs already on the teacher's roster (or repeated across pages) are skipped rather than rejected; unreadable pages are reported in an `errors` list without failing the rest. The frontend's previously-disabled "Import from PDF" button on the add-classroom screen now uploads a picked PDF and shows a summary dialog (created/updated classrooms, students added, skipped/errors). Full detail in [2026-08-03-pdf-roster-import.md](2026-08-03-pdf-roster-import.md).

4. `school_id` as integer (`backend/alembic/versions/0003_school_id_integer.py`, `backend/app/models/student.py`, `backend/app/schemas/{auth,student,parent,teacher,classroom}.py`, `backend/app/routers/auth.py`, `backend/app/services/roster.py`, `frontend/lib/models/{student,parent,teacher,classroom}.dart`, `frontend/lib/screens/auth/register_screen.dart`, `frontend/lib/widgets/roster_editor.dart`, `frontend/lib/screens/student/student_profile_screen.dart`)
   `student_profiles.school_id` changed from `String(50)` to `Integer` via an Alembic migration (`USING school_id::integer` / `::varchar` for downgrade). All backend schemas, the roster-import service, and registration now take `school_id` as `int` (with a "must be a positive number" validator instead of the old blank-string check). Frontend models parse `school_id` as `int`; the register screen and roster editor use numeric keyboards and `int.tryParse`/`int.parse` validation instead of trimming a string; the student profile screen calls `.toString()` where it needs to display it as text.

5. Default sort by classroom, then school_id (`backend/app/routers/teacher.py`, `frontend/lib/services/teacher_service.dart`)
   `GET /teacher/students` default `sort_by` changed from `surname` to `classroom`. Sorting is now driven by a column tuple per `sort_by` value instead of a single column, so `sort_by=classroom` orders by `(classroom_names, school_id)` — giving a numeric school_id tiebreaker within each classroom — while the other sort options (`name`, `surname`, `school_id`) still order by their single column. `TeacherService.listStudents`'s default `sortBy` updated to match.

## Files changed

M       backend/Dockerfile
A       backend/alembic/versions/0003_school_id_integer.py
M       backend/app/models/student.py
M       backend/app/routers/auth.py
M       backend/app/routers/teacher.py
M       backend/app/schemas/auth.py
M       backend/app/schemas/classroom.py
M       backend/app/schemas/parent.py
M       backend/app/schemas/student.py
M       backend/app/schemas/teacher.py
A       backend/app/services/pdf_roster.py
M       backend/app/services/roster.py
M       backend/requirements.txt
M       frontend/lib/main.dart
M       frontend/lib/models/classroom.dart
M       frontend/lib/models/parent.dart
M       frontend/lib/models/student.dart
M       frontend/lib/models/teacher.dart
M       frontend/lib/screens/auth/register_screen.dart
M       frontend/lib/screens/student/student_profile_screen.dart
M       frontend/lib/screens/teacher/teacher_add_classroom_screen.dart
A       frontend/lib/screens/teacher/teacher_add_grade_options_screen.dart
M       frontend/lib/screens/teacher/teacher_add_grade_screen.dart
M       frontend/lib/screens/teacher/teacher_home_screen.dart
M       frontend/lib/screens/teacher/teacher_students_screen.dart
M       frontend/lib/services/api_client.dart
M       frontend/lib/services/auth_service.dart
M       frontend/lib/services/teacher_service.dart
M       frontend/lib/widgets/roster_editor.dart
M       frontend/pubspec.yaml
