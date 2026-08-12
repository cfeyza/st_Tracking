# AI Agent Memory — Student Tracking App

> **Usage**: Read this file at the start of every session before writing any code.  
> After completing a task, update relevant sections if the task introduced a schema change, new endpoint, new feature, fixed a bug, or changed a convention.  
> Do **not** store temporary conversational context or duplicate `PROJECT_CONTEXT.md`.

---

## What This App Does

Three-role mobile/web app for Turkish schools (teacher / student / parent).  
- Teachers manage classrooms, import rosters (manual or e-Okul PDF OCR), enter grades, send FCM-pushed announcements.  
- Students redeem a teacher code → merge into teacher's roster, view grades/announcements.  
- Parents link to children via student code, see per-child announcement feed.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | FastAPI (async, Python 3.12), Uvicorn |
| ORM | SQLAlchemy 2.0 async (`asyncpg`) |
| Migrations | Alembic — sequential: `0001`–`0005` |
| DB | PostgreSQL 16 |
| Auth | JWT (`python-jose`, HS256) + bcrypt (`passlib`) |
| Email | `smtplib` (Brevo/SMTP); console-print fallback when `SMTP_HOST` empty |
| Push | Firebase Admin SDK → FCM (`firebase-admin`) |
| PDF/OCR | PyMuPDF (`fitz`) + pytesseract (Turkish, 300 DPI) |
| Frontend | Flutter / Dart (SDK ≥ 3.12.2) |
| HTTP | `http` package via `ApiClient` wrapper |
| Session | `shared_preferences` (JWT + role) |
| File pick | `file_selector` |
| FCM (FE) | `firebase_messaging` + `flutter_local_notifications` |

---

## Key File Map

```
backend/
  .env                            ← REAL SECRETS — never commit
  firebase-service-account.json   ← REAL PRIVATE KEY — never commit
  .env.example                    ← safe template (commit this)
  app/
    main.py          ← FastAPI factory; mounts auth, teacher, student, parent routers
    deps.py          ← auth guards: get_current_teacher/student/parent
    constants.py     ← DEFAULT_PAGE_SIZE = 20 (single source of truth)
    core/config.py   ← pydantic-settings, reads .env
    core/security.py ← JWT encode/decode, bcrypt, code generation
    db/session.py    ← async engine, AsyncSessionLocal, get_db
    models/
      user.py        ← User, Role enum (teacher/student/parent)
      teacher.py     ← TeacherProfile + teacher_students M2M
      student.py     ← StudentProfile (user_id NULLABLE — see invariants)
      parent.py      ← ParentProfile + parent_students M2M
      classroom.py   ← Classroom (deleted_at nullable → soft delete)
      grade.py       ← Grade (value is free String — letters or numbers)
      announcement.py← Announcement + announcement_classrooms M2M
      device_token.py← DeviceToken (FCM — unique on token)
      verification.py← EmailVerificationToken (48-hour TTL)
    routers/
      auth.py        ← /auth/register, /auth/verify-email, /auth/login
      teacher.py     ← /teacher/* (classrooms, students, grades, announcements, PDF import)
      student.py     ← /student/* (profile, teacher-code, grades, announcements, device-token)
      parent.py      ← /parent/* (profile, student-code, students, announcements)
    schemas/
      pagination.py  ← Page[T] with Page.build() class method
      (mirrors each model file)
    services/
      roster.py      ← import_roster, find_and_link_teacher_code (COMPLEX — read carefully)
      pdf_roster.py  ← parse_pdf (PyMuPDF + pytesseract, e-Okul column clustering)
      email.py       ← send_verification_email
      push.py        ← send_announcement_push (BackgroundTask — must never raise)
  alembic/versions/
    0001_initial_schema.py
    0002_nullable_student_user_id.py
    0003_school_id_integer.py
    0004_device_tokens.py
    0005_soft_delete.py          ← adds deleted_at to classrooms (LATEST)

frontend/lib/
  config.dart          ← API_BASE_URL, kDefaultPageSize = 20
  main.dart            ← app entry, route table, Firebase + FCM init
  navigation.dart      ← global navigatorKey
  firebase_options.dart← FlutterFire-generated (Web + Android only)
  models/              ← Dart models (fromJson/toJson)
  services/
    api_client.dart    ← base HTTP client (auth header, error handling)
    session.dart       ← SharedPreferences JWT/role persistence
    teacher_service.dart
    student_service.dart
    parent_service.dart
    fcm_service.dart   ← FCM permission + token registration (skipped on web)
  screens/auth/        ← LoginScreen, RegisterScreen
  screens/teacher/     ← home, profile, classrooms, students, add-classroom,
                          add-grade-options, add-grade, grades
  screens/student/     ← home, profile, add-teacher-code, grades
  screens/parent/      ← home, profile, add-student-code, students
  widgets/
    app_drawer.dart
    pagination_bar.dart← shared PaginationBar (used by all 3 role home screens)
    roster_editor.dart ← reusable student-row editor (name/surname/school_id)
```

---

## Database Schema (current — after migration 0005)

| Table | Key notes |
|---|---|
| `users` | `role` enum (teacher/student/parent); `is_verified` bool |
| `email_verification_tokens` | 48-hour TTL; hard-deleted when used or expired |
| `teacher_profiles` | `teacher_code` unique (format `TCH-XXXXXXXX`) |
| `student_profiles` | `user_id` **nullable** (placeholder rows); `school_id` **integer**; `student_code` unique |
| `parent_profiles` | name/surname only |
| `classrooms` | unique name per teacher (case-insensitive); **`deleted_at` nullable** (soft delete) |
| `grades` | `value` is `String(20)` — free text; `classroom_id` nullable (`SET NULL` on classroom delete) |
| `announcements` | free text; targets classrooms via M2M |
| `device_tokens` | FCM token; unique on token value; indexed on student_id |
| `teacher_students` | M2M: teacher ↔ student roster |
| `parent_students` | M2M: parent ↔ student |
| `classroom_students` | M2M: classroom ↔ student enrollment |
| `announcement_classrooms` | M2M: announcement ↔ target classrooms (kept on classroom soft-delete) |

---

## Critical Invariants — Never Violate These

1. **`student_profiles.user_id` must remain nullable.** Placeholder rows (teacher imports before student registers) have `user_id = NULL`. Never add a `NOT NULL` constraint.

2. **No global unique constraint on `school_id`.** Multiple teachers can each have a placeholder with the same `school_id`. Only a *verified registered account* blocks a second account from claiming that `school_id`.

3. **`school_id` is `int` (since migration 0003).** Do not revert to string.

4. **`grade.value` is a free string.** Supports both letter grades (`A`, `B+`) and numeric scores (`85`). Do not change to a numeric type.

5. **FCM push (`send_announcement_push`) must never raise.** It runs as a `BackgroundTask` after the response is sent. All exceptions must be caught and logged.

6. **Announcement targeting is classroom-scoped**, not teacher-scoped. A student only sees an announcement if enrolled in one of its target classrooms.

7. **Delete student = unlink only.** `DELETE /teacher/students/{id}` removes `teacher_students` + `classroom_students` links. The `StudentProfile` row, grade history, and other teachers'/parents' links survive.

8. **Classrooms use soft delete** (migration 0005). `DELETE /teacher/classrooms/{id}` sets `deleted_at = now()` — never hard-deletes. All classroom queries must filter `Classroom.deleted_at.is_(None)`.

9. **`DEFAULT_PAGE_SIZE = 20`** in `backend/app/constants.py` and **`kDefaultPageSize = 20`** in `frontend/lib/config.dart`. Never hardcode `20` directly.

10. **PDF parsing is PostgreSQL + Docker only.** Uses `INSERT ... ON CONFLICT DO NOTHING` (PG dialect). Tesseract in Dockerfile only — `OcrUnavailableError` on bare dev without Tesseract is expected behavior.

11. **New DB schema changes go through Alembic.** Next migration: `0006_<description>.py`. Always provide `downgrade()`.

---

## Authentication Flow

1. `POST /auth/register` → creates `User` + role profile + `EmailVerificationToken`; sends (or prints) verification email. Rejects if a *verified* `StudentProfile` already holds that `school_id`. Cleans up stale unverified user rows for the same email before creating a new one.
2. `GET /auth/verify-email?token=` → marks `user.is_verified = True`; deletes the token (or the whole row if expired).
3. `POST /auth/login` → returns `{"access_token": ..., "role": ..., "token_type": "bearer"}`. No refresh token; JWT expires after `ACCESS_TOKEN_EXPIRE_MINUTES` (default 1440 = 24 h).
4. All role-specific endpoints require `Authorization: Bearer <jwt>`. `deps.py` decodes JWT → looks up `User` → looks up role profile.

---

## Roster & Teacher-Code Linking Flow (Complex)

**Read `app/services/roster.py` before touching anything here.**

1. Teacher imports student → creates `StudentProfile(user_id=NULL)` linked to teacher and classroom (placeholder row).
2. Student registers → creates *separate* `StudentProfile(user_id=real_id)`.
3. Student redeems teacher code via `POST /student/teacher-code` → `find_and_link_teacher_code`:
   - Finds placeholder by `name + surname + school_id` (case-folded), scoped to *this teacher's* roster only.
   - Migrates classroom memberships, parent links, and grade history onto the real account.
   - Creates `teacher_students` link.
   - Hard-deletes the placeholder row (all data migrated).
4. If no matching placeholder exists → new direct teacher-student link, no placeholder involved.

---

## Pagination Pattern

All list endpoints returning potentially large sets use:

```json
{ "items": [...], "total": 120, "page": 1, "page_size": 20, "total_pages": 6 }
```

- Backend: `app/schemas/pagination.py` — `Page[T]` + `Page.build()`
- Frontend: `lib/models/paginated.dart` — `Paginated<T>`
- Paginated endpoints: classrooms, students, grades, announcements (all roles)

`listAllClassrooms` / `listAllStudents` in `TeacherService` fetch all pages in parallel (batch size 100 — intentionally not `kDefaultPageSize`) for dropdown use. Do not confuse with display pagination.

---

## Firebase / FCM

- Firebase project: `sttracking-1bcac`
- Backend: reads `firebase-service-account.json` (path from `FIREBASE_CREDENTIALS_PATH` in `.env`). Must exist at startup for push to work.
- Frontend: `lib/firebase_options.dart` — configured for Web and Android only. iOS/macOS/Windows/Linux throw `UnsupportedError`.
- Student device tokens: `POST /student/device-token` (upsert — token re-assigned on device reuse/re-login).
- Invalid/unregistered tokens are deleted from `device_tokens` after each failed FCM send.

---

## PDF Import (e-Okul OCR)

Handled by `backend/app/services/pdf_roster.py`:
1. Render each page at 300 DPI (PyMuPDF), OCR with pytesseract (`lang="tur"`).
2. Detect header row containing "ogrenci" + "no" (diacritic-folded).
3. Cluster header words into column groups by horizontal gap.
4. Bucket data-row words into columns. Columns: [1]=school_id, [2]=name, [3]=surname.
5. Extract classroom from page title regex: `(\d{1,2})\.s.n.f/([a-z])subesi` (tolerates OCR misreads of ı).
6. Duplicate school IDs in the teacher's existing roster are skipped (not rejected); other pages unaffected by a bad row.

---

## Implemented Features (as of last session)

- [x] Three-role auth (register, email verification, login)
- [x] Teacher: classroom CRUD (soft-delete), roster import (manual + PDF OCR), grade entry/list/filter/sort
- [x] Teacher: announcements (create + list + delete, paginated, FCM push on create)
- [x] Student: teacher-code redemption, grades (paginated, teacher filter, sort by date/subject/value/teacher), announcements (paginated, teacher filter)
- [x] Parent: student-code linking, announcements (paginated, per-child)
- [x] FCM push notifications (Android + Web)
- [x] Pagination across all list endpoints; shared `PaginationBar` widget (with first/last page buttons)
- [x] Global page size constant (`DEFAULT_PAGE_SIZE` / `kDefaultPageSize`)
- [x] Soft-delete for classrooms (migration 0005)
- [x] `school_id` as integer (migration 0003)
- [x] `listAllClassrooms` / `listAllStudents` fetch all pages (not capped at 100)
- [x] i18n: English + Turkish (l10n via `lib/l10n/`)

---

## Known Issues / Unfinished Features

| # | Issue |
|---|---|
| 1 | iOS / macOS / Windows / Linux FCM not configured (`UnsupportedError`). Needs FlutterFire CLI re-run. |
| 2 | Android SDK mismatch: SDK 35 vs Flutter-required 36; Android builds untested. Fix via Android Studio SDK Manager. |
| 3 | "Scan optic form" / "Read exam sheet" in teacher grade-options screen are stubbed ("Coming soon"). |
| 4 | No profile picture upload; placeholder icons only. |
| 5 | `grade.value` is a free-text field with no format validation. |
| 6 | No end-to-end integration test against a live DB. |
| 7 | Roster merge (`find_and_link_teacher_code`) tested logically but never exercised against a real PostgreSQL DB. |

---

## Development Conventions

- **New endpoint**: router in `app/routers/`, schemas in `app/schemas/`, model in `app/models/`, migration if schema changes.
- **All DB changes via Alembic** — name migrations `0006_<description>.py`, always include `downgrade()`.
- **No hardcoded `20`** — use `DEFAULT_PAGE_SIZE` (backend) / `kDefaultPageSize` (frontend).
- **Announcement targeting by classroom** — never by teacher directly.
- **Hard-delete vs. soft-delete**: only classrooms use soft-delete. Auth tokens, placeholder students, orphaned join rows, and invalid FCM tokens are hard-deleted (see `PROJECT_HISTORY.md` Session 10 for the audit table).

---

## How to Run

### Backend (local dev)
```bash
cd backend
docker compose up -d db           # start PostgreSQL
cp .env.example .env              # configure secrets
python -m venv .venv && .venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload     # http://localhost:8000/docs
```

### Full Docker stack
```bash
cd backend
docker compose up --build         # runs migrations automatically
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome                                        # web
flutter run -d <emulator-id> --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator
```

---

## Files Never to Commit

| File | Reason |
|---|---|
| `backend/.env` | JWT secret, SMTP password |
| `backend/firebase-service-account.json` | Firebase private key |

Both are in `backend/.gitignore`. Safe template: `backend/.env.example`.

---

## Update Log

| Date | Change |
|---|---|
| 2026-08-12 | File created; reflects project state after Session 10 (soft-delete, Sessions 1–10 complete). |
| 2026-08-12 | Bug: fixed back-button on home screen (initialRoute now `'/'`); Added: announcement delete (`DELETE /teacher/announcements/{id}`), first/last page in PaginationBar, page-1-reset after adding announcement, student grades sort (date/subject/value/teacher) + backend sort params. |
