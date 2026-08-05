# Student Tracking App — Backend

FastAPI + PostgreSQL backend for the student tracking app (teacher / student / parent roles).

## Stack

- FastAPI (async), Uvicorn
- SQLAlchemy 2.0 (async ORM) + asyncpg
- Alembic migrations
- JWT auth (python-jose), bcrypt password hashing (passlib)
- Email verification via SMTP (falls back to printing the link to the console if SMTP isn't configured — handy for local dev without a mail server)

## Project layout

```
backend/
  app/
    core/       # settings, security (JWT, hashing, code generation)
    db/         # engine/session setup
    models/     # SQLAlchemy models
    schemas/    # Pydantic request/response models
    routers/    # auth.py, teacher.py, student.py, parent.py
    services/   # email sending, roster import & teacher-code matching
    deps.py     # current-user / role-guard dependencies
    main.py     # FastAPI app assembly
  alembic/      # migrations
  requirements.txt
  docker-compose.yml   # Postgres (+ optional containerized API)
  Dockerfile
```

## Setup

1. Copy `.env.example` to `.env` and adjust values (at minimum set `JWT_SECRET_KEY` to a long random string, and `DATABASE_URL` if not using the defaults below).

2. Start Postgres. Either via Docker:

   ```bash
   docker compose up -d db
   ```

   or point `DATABASE_URL` at a Postgres instance you already have running.

3. Create a virtualenv and install dependencies:

   ```bash
   python -m venv .venv
   .venv/Scripts/activate   # Windows
   pip install -r requirements.txt
   ```

4. Run migrations:

   ```bash
   alembic upgrade head
   ```

5. Run the API:

   ```bash
   uvicorn app.main:app --reload
   ```

   Interactive docs at `http://localhost:8000/docs`.

Alternatively, `docker compose up --build` runs Postgres + the API together (the API container runs migrations automatically on start).

## Auth flow

- `POST /auth/register` — role (`teacher`/`student`/`parent`), name, surname, email, password (`school_id` required for students). Creates the account unverified, generates a `teacher_code`/`student_code` where applicable, and sends a verification email.
- `GET /auth/verify-email?token=...` — the link sent by email; marks the account verified.
- `POST /auth/login` — email + password. Rejects unverified accounts (403) and wrong credentials (401). Returns a JWT plus the user's `role`, so the frontend knows which main page to route to.

All role-specific endpoints require `Authorization: Bearer <token>` and are guarded by role (a student token can't hit `/teacher/*`, etc).

## Classroom rosters & the teacher-code matching flow

Teachers own their classroom rosters — students never have to be manually sorted into the right classroom after the fact:

1. **Teacher creates/populates a classroom** via `POST /teacher/classrooms` (optionally with an initial `students: [{name, surname, school_id}, ...]` list) or adds more later via `POST /teacher/classrooms/{id}/roster`. Each roster row becomes a `StudentProfile` row immediately — even though no one has registered an account for it yet (`user_id` is `NULL`). It's already linked to the teacher and enrolled in that classroom.
   - `POST /teacher/classrooms/{id}/roster/pdf` exists as a stub (returns `501 Not Implemented`) for a future PDF-upload version of the same import — send me a sample roster PDF layout when you're ready to build that out for real.
   - Re-importing a `school_id` the teacher already has (e.g. the same student appearing in a second classroom) reuses the existing row instead of creating a duplicate.
2. **Student registers normally** (`POST /auth/register`) — this always creates their own fresh `StudentProfile`, independent of any roster a teacher may have already imported for them.
3. **Student redeems the teacher's code** (`POST /student/teacher-code`). The backend looks for a placeholder roster row under that specific teacher matching on **name + surname + school_id**. If found, it merges that row's classroom memberships, any parent links, and any grades already entered onto the student's real account, links the teacher, and discards the placeholder — this is "the teacher's data is found and shown to the student." If no matching roster row exists, the call fails with a clear 404 telling the student to ask their teacher to add them to a roster first (no silent fallback to an unassigned link).

This means `GET /teacher/students` can return students who haven't registered yet (check the `is_registered` field) alongside ones who have — the teacher's view of their classrooms doesn't depend on registration status at all.

Matching is deliberately scoped **per teacher** — if the same physical student is on two different teachers' rosters, each is a separate placeholder row until that student redeems each teacher's code individually. This avoids one teacher's data ever being linked based on another teacher's roster.

## Design decisions worth knowing about

A few things in the spec were implied rather than spelled out; here's how they were resolved so the Flutter side can be built against something concrete:

- **Announcement targeting**: an announcement always targets one or more of the teacher's classrooms. A student only sees an announcement in their feed if they're enrolled in at least one of its target classrooms (not just "any subscribed teacher"). Parents see the union of their linked students' feeds, each tagged with the student's name.
- **Grades**: modeled as `subject` + `value` (string, so it can hold letter grades or numeric scores) tied to a teacher, student, and optionally a classroom. Endpoints exist (`POST/GET /teacher/grades`, `GET /student/grades`) but no dedicated grade-entry page was specified yet — wire this up once that page's design is set.
- **IDs**: integer primary keys throughout, not UUIDs — simpler to work with from Flutter/JSON for a school-scale app.

## API summary

| Method | Path | Who | Purpose |
|---|---|---|---|
| POST | /auth/register | anyone | create account, sends verification email |
| GET | /auth/verify-email | anyone | verify email via emailed link |
| POST | /auth/login | anyone | get JWT + role |
| GET | /teacher/me | teacher | profile page data |
| GET | /teacher/dashboard | teacher | classroom/student counts |
| POST/GET | /teacher/classrooms | teacher | create classroom (with optional initial roster) / list classrooms |
| POST | /teacher/classrooms/{id}/roster | teacher | add students to a classroom by name/surname/school_id |
| POST | /teacher/classrooms/{id}/roster/pdf | teacher | **stub** — PDF roster import, not implemented yet (501) |
| GET | /teacher/students | teacher | MYSTUDENTS_T — filter by classroom, sort by classroom/name/surname/school_id, includes `is_registered` |
| POST/GET | /teacher/announcements | teacher | create / list announcements |
| POST/GET | /teacher/grades | teacher | add / list grades |
| GET | /student/me | student | profile page data |
| POST | /student/teacher-code | student | redeem a teacher code — matches & merges the teacher's roster entry onto this account |
| GET | /student/announcements | student | announcement feed |
| GET | /student/grades | student | own grades |
| GET | /parent/me | parent | profile page data |
| POST | /parent/student-code | parent | link to a student |
| GET | /parent/students | parent | MYSTUDENTS_P |
| GET | /parent/announcements | parent | announcement feed (tagged with student name) |

## Verified so far

- All models compile to valid PostgreSQL DDL (checked via `CreateTable(...).compile(dialect=postgresql.dialect())`), including `student_profiles.user_id` now being nullable.
- Both Alembic migrations (`0001_initial`, `0002_roster_placeholders`) were validated with `alembic upgrade head --sql` (offline SQL generation) — no live Postgres was available in the dev sandbox to run them end-to-end, so run `alembic upgrade head` against a real database before first use and sanity-check it.
- The FastAPI app imports cleanly and all routes register as expected (checked via `TestClient` against `/openapi.json`).
- The roster merge logic (`app/services/roster.py`) uses Postgres's `INSERT ... ON CONFLICT DO NOTHING`, so it's Postgres-only by design (matches the rest of the stack) — it hasn't been exercised against a real database yet, only reviewed logically. Worth a real end-to-end test (register a placeholder via roster import, then register + redeem the code as a student) once Postgres is reachable.
