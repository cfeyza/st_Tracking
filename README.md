# Student Tracking App

A teacher / student / parent app: FastAPI + PostgreSQL backend, Flutter frontend.

```
student_tracking_app/
  backend/    FastAPI + PostgreSQL API (see backend/README.md for API details)
  frontend/   Flutter app (login/register + teacher/student/parent screens)
```

## Is everything done already?

**No — three real gaps before this runs end-to-end**, everything else is built:

1. **No PostgreSQL database exists yet.** The backend has never been run against a live database in this environment (no Docker, no local Postgres install here) — only validated statically (DDL compilation, offline migration SQL). You need to actually stand one up.
2. **The frontend has never talked to the backend.** Both were built and verified independently. The plumbing (API client, models, screens) is done, but this exact pairing has not been exercised together yet.
3. **Two features are intentionally stubbed, not missing by accident**: PDF roster import (`POST /teacher/classrooms/{id}/roster/pdf` returns 501; the frontend has a disabled "coming soon" button for it) and profile pictures (the drawer/profile screens show a placeholder icon — there's no upload endpoint or image storage anywhere).

Everything else — auth with email verification, all three role's main/profile pages, classroom roster import, the teacher-code matching flow, announcements, grades — is fully built on both sides and should work once you complete the steps below.

## Step-by-step: getting it running

### 1. Stand up PostgreSQL

Pick one:

- **Docker** (easiest, if you have Docker Desktop installed):
  ```bash
  cd backend
  docker compose up -d db
  ```
- **Native install**: install PostgreSQL, then create a database and user matching `backend/.env.example`'s defaults (or edit `.env` to match what you create):
  ```sql
  CREATE USER student_tracking_user WITH PASSWORD 'changeme';
  CREATE DATABASE student_tracking OWNER student_tracking_user;
  ```

### 2. Set up and run the backend

```bash
cd backend
cp .env.example .env
```
Edit `.env`: at minimum set `JWT_SECRET_KEY` to a long random string. Leave `SMTP_HOST` blank for now — verification emails will just print to the console instead of actually sending, which is enough to test registration locally.

```bash
python -m venv .venv
.venv/Scripts/activate
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

This is the step that's never actually been run in this build — **watch the `alembic upgrade head` output carefully** for errors. It was hand-verified via offline SQL generation, but that's not the same as a real run.

Confirm it's up: open `http://localhost:8000/docs` — you should see the interactive API docs.

### 3. Point the frontend at the backend

The frontend reads its API URL from a compile-time constant (`frontend/lib/config.dart`), defaulting to `http://localhost:8000`. Override it with `--dart-define` per platform:

| Target | Command |
|---|---|
| Chrome / web | `flutter run -d chrome` (default `localhost:8000` works as-is) |
| Windows desktop | `flutter run -d windows` (also `localhost:8000` works as-is) |
| Android emulator | `flutter run -d <emulator-id> --dart-define=API_BASE_URL=http://10.0.2.2:8000` (the emulator can't reach the host as `localhost`) |
| Physical phone | `flutter run -d <device-id> --dart-define=API_BASE_URL=http://<your-computer's-LAN-IP>:8000` — also set `CORS_ORIGINS` in the backend's `.env` if needed, and make sure both devices are on the same network/Wi-Fi |

```bash
cd frontend
flutter pub get   # only needed if you haven't already
flutter run -d chrome
```

### 4. Actually test the flow

This exact sequence has not been run yet — it's the real integration test:

1. Register as a **teacher** → check the backend console for the printed verification email (since SMTP isn't configured) → hit that verify link → log in.
2. From the teacher's drawer, **add a classroom** with a small roster (name/surname/school ID for 1-2 students).
3. Register as a **student** using the *exact same* name/surname/school ID you just put on the roster.
4. Log in as that student, open the drawer, **add teacher code** (the teacher's code is on their profile page) → you should see a "linked to classroom X" confirmation.
5. Back on the teacher's side, post an **announcement** targeting that classroom, and **add a grade** for that student.
6. Log back in as the student → both should now show up on their home/grades screens.
7. Register as a **parent**, add the student's code (student's profile page) → confirm the parent's announcement feed shows the same announcement tagged with the student's name.

If step 4 gives you a 404 ("no matching student record"), the name/surname/school_id typed at student registration didn't exactly match what the teacher entered on the roster — that matching is intentionally strict (see `backend/README.md`'s roster section for why).

## Android specifically

`flutter doctor` in this environment currently reports the installed Android SDK is one version behind what this Flutter release wants (SDK 35 vs required 36, plus BuildTools 28.0.3) — Android builds haven't been tried here as a result. Web and Windows desktop builds work fine as substitutes for checking the UI. To actually target Android, run `flutter doctor` yourself and follow its prompt to update the SDK/BuildTools via Android Studio's SDK Manager.

## What's been verified vs. what hasn't

**Verified:**
- Backend: all models compile to valid PostgreSQL DDL, both Alembic migrations validated via offline SQL generation, FastAPI app imports and all routes register correctly.
- Frontend: `flutter analyze` clean, widget test passes, full app compiles and serves on Chrome with no console errors (checked via network + console logs).

**Not verified (because Postgres/Docker/a real device aren't available in this build environment):**
- Backend against a real database — any query has never actually executed.
- Frontend calling the backend — the two have never made a real HTTP request to each other.
- The teacher-code matching/merge logic (`app/services/roster.py`) — logically reviewed, never run.
- Android builds.

Run the step-by-step flow above once Postgres is available — that's the one thing left standing between this and a working demo.
