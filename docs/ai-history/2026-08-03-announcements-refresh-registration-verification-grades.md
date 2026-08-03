# Announcement refresh, registration cleanup, verification token expiry, and teacher grades page

## Summary

Fix the student/parent announcement board not updating right after linking to a new teacher/student, clean up the registration flow after the verification email is sent, expire and delete stale email-verification tokens after 48 hours (and let the associated email register again), and add a paginated/filterable/sortable "Grades" page for teachers with click-through from My Students.

## Prompt
○Announcements board on students homepage shows the student's subscribed teachers' announcements regarding to the students classroom. (i.e. if a student linked to teacher A and the students is in classroom B, the board shows theacher A's all announcements of classroom, B past and present)

I guess the bug is in here : "After linking, the app doesn't need to log off and on to Show the updated announcement board of the student."

○ When a new person registers, after the "verification mail sent, please check your box" snackbar message, registration form must be cleaned and the page must be directed to login page.

○After sending an email verification link and creating a verification token, system shows its lifetime a 48 hours. After 48 hours, delete the token from the system.
(In the version we already have, mail gets killed by the system, if someone gets the token but doesn't use it in 48 hours, the already dead token linked to that mail disabled the mail to register ever. Delete the token and link, person should register with infos again to get another verification mail)

○Create a new button in the teacher's drawer, named 'Grades'. This button opens a page with tableview of grades of all students, (as in my Students page, use pagination) Create the necessary filtering and sorting options.
○If one of the students gets clicked in the my students page, the page will be directed to 'grades' page with filtering applied as that student.

## Response

1. Announcement board didn't refresh after linking (frontend/lib/screens/student/student_home_screen.dart, frontend/lib/screens/parent/parent_home_screen.dart)
The homepage loaded its announcement/board list once in `initState`, but the "Add teacher code" (student) and "Add student code" (parent) drawer actions never refetched it on return — the newly-linked teacher's classroom announcements only showed up after a full app restart re-ran `initState`. Both drawer actions now `await` the navigation to the linking screen and call `_refresh()` (which re-runs `StudentService.listAnnouncements()` / the parent equivalent) immediately after, so the board is current without logging off and on.
   - Also (backend/app/services/roster.py, backend/app/routers/teacher.py `add_to_roster`): loosened the roster-import duplicate check that a previous change had made too strict. It was rejecting a new placeholder student whenever the school ID matched a *different, already-registered* account anywhere in the system — but that's the normal cross-teacher pattern this linking flow depends on (a student can have an unclaimed placeholder row under teacher A and a separate registered account claimed via teacher B's code; only redeeming teacher A's own code should ever merge the two). Now only a school ID already on *this teacher's own* roster is rejected with 409; a match against a different teacher's placeholder or another registered account is left alone for the teacher-code redemption flow to resolve.

2. Registration form reset + redirect on success (frontend/lib/screens/auth/register_screen.dart)
After the "verification email sent, check your inbox" snackbar fires, the form now resets (`_formKey.currentState!.reset()`), all text controllers are cleared, and the role selector is reset to `student`, before navigating to `/login` via `pushNamedAndRemoveUntil`.

3. Verification token 48-hour expiry and cleanup (backend/app/routers/auth.py)
The 48-hour TTL itself already existed (`settings.EMAIL_VERIFICATION_TOKEN_EXPIRE_HOURS = 48`), but nothing ever deleted an expired token or unblocked its email:
   - `GET /auth/verify-email`: clicking an expired link now deletes that token row immediately (previously it just returned 400 and left the dead row in place forever).
   - `POST /auth/register`: previously, any unverified existing user permanently blocked that email from ever registering again, even once its token had expired, with no path back in. Now, if the existing unverified user still has a live (non-expired) token, registration is still blocked with a "check your inbox for the verification link" message; if the token is expired (or missing), the stale user row is deleted and the request proceeds as a brand-new registration — issuing a fresh token and sending a new verification email.

4. Teacher "Grades" page (drawer button, filters/sort/pagination, click-through from My Students)
   - New file `frontend/lib/screens/teacher/teacher_grades_screen.dart`: a `DataTable` of grades (student, subject, grade, classroom, date) with a student filter dropdown, a classroom filter dropdown, a sort-by dropdown (student/subject/grade/classroom/date), an ascending/descending toggle, and a page prev/next bar — the same pagination pattern as `teacher_students_screen.dart`. It accepts an optional initial student id/name so it can open pre-filtered.
   - `frontend/lib/screens/teacher/teacher_home_screen.dart`: new drawer entry "Grades" → `/teacher/grades`.
   - `frontend/lib/main.dart`: new `/teacher/grades` route wired to `TeacherGradesScreen`, passing through optional `studentId`/`studentName` route arguments.
   - `frontend/lib/screens/teacher/teacher_students_screen.dart`: each row in My Students is now clickable (`onSelectChanged`) and navigates to `/teacher/grades` with that student's id/name as the initial filter; `showCheckboxColumn: false` hides the selection checkboxes that `onSelectChanged` would otherwise add to the table.
   - `frontend/lib/services/teacher_service.dart`: `listGrades()` now returns `Paginated<Grade>` and takes `classroomId`, `sortBy`, `order`, `page`, and `pageSize` parameters instead of just an optional `studentId`.
   - `backend/app/routers/teacher.py`: `GET /teacher/grades` now returns `Page[GradeOut]` (reusing the existing `Page` wrapper from the classrooms/students pagination work) and adds a `classroom_id` filter plus `sort_by` (student/subject/value/classroom/date) and `order` (asc/desc) query params, backed by a joined, ordered, `LIMIT`/`OFFSET` query with a real `COUNT` instead of the old teacher-id-only, created-at-desc-only list.

## Files changed

M       backend/app/routers/auth.py
M       backend/app/routers/teacher.py
M       backend/app/services/roster.py
M       frontend/lib/main.dart
M       frontend/lib/screens/auth/register_screen.dart
M       frontend/lib/screens/parent/parent_home_screen.dart
M       frontend/lib/screens/student/student_home_screen.dart
M       frontend/lib/screens/teacher/teacher_home_screen.dart
M       frontend/lib/screens/teacher/teacher_students_screen.dart
M       frontend/lib/services/teacher_service.dart
A       frontend/lib/screens/teacher/teacher_grades_screen.dart
