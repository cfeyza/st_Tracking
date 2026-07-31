# School ID uniqueness and copyable codes

## Summary

Prevent a new student (self-registration or teacher roster import) from being created with a school ID that already belongs to a registered student account. Make the teacher code and student code on the profile screens tap-to-copy.

## Prompt
-A new student (or a classroom with a new student) can't be created with an already existing school_id
-Let the teacher and student codes can be copied (via clicking on it)
-When add classroom option is clicked, if there is already a student with the id teacher tries to add, it must reject.
-It should not be legitimate to add anywhere a new student with an already existing id.

## Response

1. School ID uniqueness (backend/app/routers/auth.py, backend/app/services/roster.py)
`school_id` has no DB-level unique constraint by design: a physical student can have several teacher-owned placeholder `StudentProfile` rows (one per teacher who hasn't been "claimed" via a `/student/teacher-code` redemption yet) that all share the same school ID until each is individually merged into the student's real account. Blocking that pattern would break the existing multi-teacher roster flow, so the fix targets the actual bug: nothing stopped a **new** profile from being created with a school ID that already belongs to an **already-registered** account (`user_id` set).
   - `POST /auth/register`: rejects with 409 if a `StudentProfile` with the same `school_id` and a non-null `user_id` already exists.
   - `import_roster` (used by `POST /teacher/classrooms` and `POST /teacher/classrooms/{id}/roster`): when a roster entry doesn't match an existing student already linked to this teacher, it now also rejects with 409 if the school ID belongs to a different, already-registered student — with a message pointing the teacher to the teacher-code flow instead.
   - Unregistered placeholder rows (`user_id is None`) are unaffected — the existing per-teacher reuse/merge behavior stays intact.
   - Also fixed roster entries not being `.strip()`-ped before the initial existing-student lookup, which could cause a false "not found" on the very row it was about to duplicate.

2. Copyable codes (frontend/lib/screens/teacher/teacher_profile_screen.dart, frontend/lib/screens/student/student_profile_screen.dart)
`_ProfileField` gained a `copyable` flag. When set, the value is wrapped in an `InkWell` with a small copy icon; tapping copies it via `Clipboard.setData` and shows a confirmation snackbar. Applied to the teacher code on the teacher profile screen and the student code on the student profile screen.

3. Reject duplicate school IDs everywhere a "new" student can be added (backend/app/services/roster.py, backend/app/routers/teacher.py)
`import_roster` previously reused/merged a roster entry whose school ID matched a student this teacher already knew, silently linking that existing student into the classroom instead of failing. That was first narrowed to only the "New classroom" flow (via a `reject_duplicates` flag), then — per your follow-up that this should never be legitimate through *any* manual roster entry — the flag was removed entirely: `import_roster` now unconditionally rejects with 409 ("A student with school ID '…' already exists in your roster.") whenever a roster row's school ID matches a student already in this teacher's roster, whether the request came from `create_classroom` (new classroom) or `add_to_roster` (adding to an existing classroom). There's currently no separate UI/endpoint for "enroll a student I already have into another of my classrooms" — re-typing their details into a roster row is treated as a mistake, not that workflow.
   - The cross-teacher placeholder pattern is untouched: a *different* teacher can still import the same school ID as their own new placeholder (needed for that student to later redeem that teacher's code) — only a match against an already-registered account, or against this same teacher's own roster, is rejected.

## Files changed

M       backend/app/routers/auth.py
M       backend/app/routers/teacher.py
M       backend/app/services/roster.py
M       frontend/lib/screens/teacher/teacher_profile_screen.dart
M       frontend/lib/screens/student/student_profile_screen.dart
