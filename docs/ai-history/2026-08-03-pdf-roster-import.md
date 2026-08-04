# PDF class-roster import

## Summary

Let a teacher upload an e-Okul style class-list PDF and have the app OCR it, detect the classroom (e.g. "9A") from each page's title, and bulk-create the roster — no retyping, no pre-selecting a classroom.

## Prompt

@07163300_siniflisteleri-1.pdf
Let's add the feature: PDF import

When importing a pdf, source file will be as in attached file.
"Öğrenci No" corresponds to school_id
"Adı" corresponds to student name
"Soyadı" corresponds to student surname

There will be title (like 'AL - 9. Sınıf / A şubesi (...) Sınıf Listesi'), this title means the classroom is 9A

The app needs to read those information from the file and bulk creates the students with their class.

Follow-up decisions: support multiple classrooms in one PDF upload (one per page, partial success per page), and OCR runs via Tesseract in Docker only (not required on the bare dev machine).

## Response

1. PDF/OCR parsing (`backend/app/services/pdf_roster.py`, new file)
   The sample file turned out to be a scanned image with no text layer at all (confirmed via pymupdf: 0 extractable chars). Each page is reduced to a flat list of words with positions — from the real text layer when one exists, otherwise from `pytesseract.image_to_data` (Turkish language pack) after rendering the page at 300 DPI. The header row's words are clustered into columns by horizontal gap (not by splitting on whitespace, which OCR doesn't reliably preserve), and every later row's words are bucketed into those same column ranges to reconstruct `Öğrenci No | Adı | Soyadı`. The classroom title (e.g. "9. Sınıf / A Şubesi" → "9A") is matched with a Turkish-diacritic-folding regex tolerant of common OCR confusions (dotless ı gets misread as `1`, `l`, or even `a`). A page that can't be read (no title, no table, OCR unavailable) reports an error for that page only — one bad page doesn't fail the rest.

2. Endpoint (`backend/app/routers/teacher.py`)
   Replaced the existing 501 stub (`POST /classrooms/{classroom_id}/roster/pdf`) with `POST /teacher/classrooms/import/pdf` — not scoped to a single classroom, since one PDF can contain several. For each page: finds or creates the classroom by name (same case-insensitive match as `create_classroom`), pre-filters any `school_id` already on the teacher's roster (from before this upload or an earlier page in the same PDF) into a `skipped` list, and passes the rest to the existing `import_roster` service unchanged. Returns a per-classroom summary (`created_classroom`, `students_added`, `skipped`) plus a page-level `errors` list.

3. Frontend (`teacher_add_classroom_screen.dart`, `api_client.dart`, `teacher_service.dart`, `models/classroom.dart`)
   Replaced the disabled "Import from PDF (coming soon)" button with a working one: `file_picker` → `ApiClient.postMultipart` (new helper, `http.MultipartRequest`) → summary dialog (classrooms created/updated, students added, skipped/errors) → pops back to refresh the classroom list. Independent of the existing new/existing-classroom toggle above it, since the PDF supplies its own classroom name(s).

4. Docker (`backend/Dockerfile`)
   Added `tesseract-ocr` + `tesseract-ocr-tur` via apt, and `pymupdf`/`pytesseract`/`Pillow` to `requirements.txt`.

## Verification

Installed Tesseract locally (with the Turkish language pack) to test against the real sample PDF rather than relying on synthetic data:
- `parse_pdf` on the actual scanned file: correctly detected classroom "9A" and parsed 37 of 38 rows (1 skipped as an unreadable-row warning — a genuine OCR digit misread ("91" → "gi"), not a parsing bug).
- Full HTTP-level test: spun up the project's Postgres container, ran migrations, registered/verified/logged in a test teacher, and POSTed the PDF to `/teacher/classrooms/import/pdf` — got back `{"classrooms": [{"classroom_name": "9A", "created_classroom": true, "students_added": 37, "skipped": []}], "errors": [...one warning...]}`.
- Re-uploaded the same PDF — confirmed idempotent duplicate handling: same classroom reused (`created_classroom: false`), `students_added: 0`, all 37 correctly reported in `skipped`.
- `flutter analyze`: no issues.
- Test data (one teacher account, one "9A" classroom, 37 placeholder students) was created directly in the project's real dev database (a pre-existing Docker-named volume, not a throwaway one) and was fully removed afterward, verified by row count before/after.

## Files changed

A       backend/app/services/pdf_roster.py
M       backend/app/routers/teacher.py
M       backend/app/schemas/classroom.py
M       backend/requirements.txt
M       backend/Dockerfile
M       frontend/pubspec.yaml
M       frontend/lib/services/api_client.dart
M       frontend/lib/services/teacher_service.dart
M       frontend/lib/models/classroom.dart
M       frontend/lib/screens/teacher/teacher_add_classroom_screen.dart
