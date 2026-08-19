"""Tests for app/services/pdf_roster.py.

How this file is structured
----------------------------
1. Unit tests — pure helper functions, no PDF or Tesseract involved.
2. Component tests — _parse_page logic tested by mocking _get_words_and_width
   so we control exactly which words appear at which x positions.
3. Integration / smoke tests — parse_pdf called with a real (minimal) PDF
   to verify the full pipeline runs end-to-end on the text-layer path.

Running the tests
-----------------
From the backend/ directory:

    .venv/Scripts/pytest tests/ -v

Or just run a single test file:

    .venv/Scripts/pytest tests/test_pdf_roster.py -v
"""

from unittest.mock import patch

import fitz  # pymupdf — used only to build the smoke-test PDF
import pytest

from app.services.pdf_roster import (
    OcrUnavailableError,
    _Word,
    _assign_column,
    _cluster_columns,
    _fold,
    _group_lines,
    _parse_page,
    parse_classroom_name,
    parse_pdf,
)

# ---------------------------------------------------------------------------
# Shared geometry used by component tests
# ---------------------------------------------------------------------------
# These x positions mimic a realistic e-Okul page (A4, ~595pt wide).
# The gap between adjacent columns is ~25pt, well above the 14.9pt threshold
# (_COLUMN_GAP_FRACTION=0.025 × 595). Words within "Öğrenci No" (two words,
# one column) are 5pt apart — below the threshold — so they cluster together.

PAGE_W = 595.0

# (left, right) for each column
_X_SNO = (30.0, 70.0)
_X_SCHOOL = (90.0, 165.0)   # "Öğrenci" 90-130, "No" 135-165 → same cluster
_X_NAME = (190.0, 280.0)
_X_SURNAME = (305.0, 400.0)
_X_GENDER = (425.0, 480.0)
_X_BOARD = (505.0, 575.0)


def _w(text: str, x: tuple[float, float], line: int, block: int = 0) -> _Word:
    """Convenience: create a _Word at the given (left, right) position."""
    return _Word(text=text, left=x[0], right=x[1], line_key=(block, line))


def _header_words(line: int = 0) -> list[_Word]:
    """The standard e-Okul header row (folded ASCII, as OCR would produce)."""
    return [
        _w("S.No", _X_SNO, line),
        _w("Ogrenci", _X_SCHOOL, line),          # left half of the column
        _w("No", (135.0, 165.0), line),           # right half — same cluster
        _w("Adi", _X_NAME, line),
        _w("Soyadi", _X_SURNAME, line),
        _w("Cinsiyeti", _X_GENDER, line),
        _w("Pansiyon", _X_BOARD, line),
    ]


def _student_words(sno: str, school_id: str, name: str, surname: str, line: int) -> list[_Word]:
    return [
        _w(sno, _X_SNO, line),
        _w(school_id, _X_SCHOOL, line),
        _w(name, _X_NAME, line),
        _w(surname, _X_SURNAME, line),
        _w("E", _X_GENDER, line),
        _w("Hayir", _X_BOARD, line),
    ]


def _footer_words(line: int) -> list[_Word]:
    """The summary line that signals end-of-table."""
    return [
        _w("Ogrenci", _X_SNO, line),
        _w("Sayisi:", (80.0, 140.0), line),
        _w("2", (150.0, 165.0), line),
    ]


def _make_words_and_width(rows: list[list[_Word]]) -> tuple[list[_Word], float]:
    return [w for row in rows for w in row], PAGE_W


# ---------------------------------------------------------------------------
# 1. Unit tests — _fold
# ---------------------------------------------------------------------------

class TestFold:
    def test_lowercases_ascii(self):
        assert _fold("HELLO") == "hello"

    def test_strips_turkish_diacritics(self):
        # Every Turkish special character should map to its ASCII equivalent
        assert _fold("çÇğĞıIİöÖşŞüÜ") == "ccggiiioossuu"

    def test_mixed_string(self):
        # Real header word as OCR might produce it
        assert _fold("Öğrenci") == "ogrenci"


# ---------------------------------------------------------------------------
# 2. Unit tests — parse_classroom_name
# ---------------------------------------------------------------------------

class TestParseClassroomName:
    def test_standard_format(self):
        text = "AL - 9. Sinif / A Subesi (ALANI YOK) Sinif Listesi"
        assert parse_classroom_name(text) == "9A"

    def test_two_digit_grade(self):
        assert parse_classroom_name("12. Sinif / B Subesi") == "12B"

    def test_ocr_mangled_i(self):
        # OCR frequently misreads ı as 1, l, or a — the regex uses . wildcards
        assert parse_classroom_name("9. s1n1f / c subesi") == "9C"

    def test_uppercase_section_is_normalised(self):
        result = parse_classroom_name("9. Sinif / A Subesi")
        assert result == "9A"

    def test_returns_none_when_no_match(self):
        assert parse_classroom_name("Bu bir test satiridir") is None

    def test_returns_none_for_empty_string(self):
        assert parse_classroom_name("") is None


# ---------------------------------------------------------------------------
# 3. Unit tests — _group_lines
# ---------------------------------------------------------------------------

class TestGroupLines:
    def test_groups_words_by_line_key(self):
        words = [
            _Word("hello", 0.0, 30.0, (0, 0)),
            _Word("world", 35.0, 70.0, (0, 0)),
            _Word("next", 0.0, 30.0, (0, 1)),
        ]
        lines = _group_lines(words)
        assert len(lines) == 2
        assert [w.text for w in lines[0]] == ["hello", "world"]
        assert [w.text for w in lines[1]] == ["next"]

    def test_words_within_line_sorted_left_to_right(self):
        words = [
            _Word("right", 50.0, 80.0, (0, 0)),
            _Word("left", 10.0, 40.0, (0, 0)),
        ]
        lines = _group_lines(words)
        assert [w.text for w in lines[0]] == ["left", "right"]

    def test_line_order_matches_insertion_order(self):
        words = [
            _Word("second", 0.0, 40.0, (0, 1)),
            _Word("first", 0.0, 40.0, (0, 0)),
        ]
        lines = _group_lines(words)
        # The first line encountered (block=0, line=1) appears first
        assert lines[0][0].text == "second"
        assert lines[1][0].text == "first"


# ---------------------------------------------------------------------------
# 4. Unit tests — _cluster_columns
# ---------------------------------------------------------------------------

class TestClusterColumns:
    def test_two_well_separated_words(self):
        words = [
            _Word("Left", 30.0, 80.0, (0, 0)),
            _Word("Right", 200.0, 260.0, (0, 0)),
        ]
        bounds = _cluster_columns(words, PAGE_W)
        assert len(bounds) == 2
        # First column starts at page left edge
        assert bounds[0][0] == 0.0
        # Last column ends at page right edge
        assert bounds[-1][1] == PAGE_W

    def test_two_close_words_merge_into_one_cluster(self):
        # Gap of 5pt is below the 14.9pt threshold
        words = [
            _Word("Ogrenci", 90.0, 130.0, (0, 0)),
            _Word("No", 135.0, 165.0, (0, 0)),
        ]
        bounds = _cluster_columns(words, PAGE_W)
        assert len(bounds) == 1

    def test_full_header_produces_six_clusters(self):
        bounds = _cluster_columns(_header_words(), PAGE_W)
        assert len(bounds) == 6


# ---------------------------------------------------------------------------
# 5. Unit tests — _assign_column
# ---------------------------------------------------------------------------

class TestAssignColumn:
    def test_center_falls_in_correct_bucket(self):
        bounds = [(0.0, 100.0), (100.0, 200.0), (200.0, 595.0)]
        word = _Word("x", 110.0, 150.0, (0, 0))  # center = 130 → bucket 1
        assert _assign_column(word, bounds) == 1

    def test_returns_none_when_out_of_any_bound(self):
        bounds = [(50.0, 100.0)]
        word = _Word("x", 10.0, 30.0, (0, 0))  # center = 20, below range
        assert _assign_column(word, bounds) is None


# ---------------------------------------------------------------------------
# 6. Component tests — _parse_page (mocked _get_words_and_width)
# ---------------------------------------------------------------------------

class TestParsePage:
    """Each test creates synthetic _Word objects and patches _get_words_and_width
    so _parse_page never touches a real PDF file or Tesseract."""

    def _run(self, rows: list[list[_Word]]) -> "PageParseResult":  # noqa: F821
        words, width = _make_words_and_width(rows)
        # A MagicMock stands in for fitz.Page — _parse_page only passes it to
        # _get_words_and_width, which we replace entirely.
        from unittest.mock import MagicMock
        mock_page = MagicMock()
        with patch("app.services.pdf_roster._get_words_and_width", return_value=(words, width)):
            from app.services.pdf_roster import _parse_page
            return _parse_page(mock_page, page_number=1)

    def test_happy_path_extracts_correct_students(self):
        title_words = [_w("9. Sinif / A Subesi", (30.0, 200.0), line=0)]
        rows = [
            title_words,
            _header_words(line=1),
            _student_words("1", "12345", "AHMET", "YILMAZ", line=2),
            _student_words("2", "12346", "FATMA", "KAYA", line=3),
            _footer_words(line=4),
        ]
        result = self._run(rows)

        assert result.error is None
        assert result.classroom_name == "9A"
        assert len(result.entries) == 2
        assert result.entries[0].name == "AHMET"
        assert result.entries[0].surname == "YILMAZ"
        assert result.entries[0].school_id == 12345
        assert result.entries[1].name == "FATMA"
        assert result.entries[1].school_id == 12346

    def test_footer_stops_row_parsing(self):
        rows = [
            _header_words(line=0),
            _student_words("1", "12345", "AHMET", "YILMAZ", line=1),
            _footer_words(line=2),
            # This row is after the footer — must NOT be included
            _student_words("2", "99999", "GHOST", "ROW", line=3),
        ]
        result = self._run(rows)
        assert len(result.entries) == 1
        assert result.entries[0].school_id == 12345

    def test_unreadable_row_generates_warning_not_error(self):
        # "ABC" is not a valid numeric school_id → row should be skipped with warning
        rows = [
            _header_words(line=0),
            [_w("1", _X_SNO, 1), _w("ABC", _X_SCHOOL, 1), _w("AHMET", _X_NAME, 1), _w("YILMAZ", _X_SURNAME, 1)],
            _student_words("2", "12346", "FATMA", "KAYA", line=2),
        ]
        result = self._run(rows)

        # The bad row is skipped, the good one is kept
        assert len(result.entries) == 1
        assert result.entries[0].school_id == 12346
        # A warning was recorded (not an error — the page itself was usable)
        assert len(result.warnings) == 1
        assert result.error is None

    def test_missing_header_returns_error(self):
        # No line contains both "ogrenci" and "no"
        rows = [
            [_w("Bu", (30.0, 60.0), 0), _w("bir", (65.0, 90.0), 0), _w("sayfa", (95.0, 140.0), 0)],
        ]
        result = self._run(rows)
        assert result.error is not None
        assert "Öğrenci No" in result.error

    def test_too_few_columns_returns_error(self):
        # Header found but only 3 words → 3 clusters → < 4 columns required
        sparse_header = [
            _w("Ogrenci", _X_SCHOOL, 0),
            _w("No", (135.0, 165.0), 0),
            _w("Adi", _X_NAME, 0),
        ]
        rows = [sparse_header]
        result = self._run(rows)
        assert result.error is not None

    def test_ocr_unavailable_propagated_as_error(self):
        from unittest.mock import MagicMock
        mock_page = MagicMock()
        with patch(
            "app.services.pdf_roster._get_words_and_width",
            side_effect=OcrUnavailableError("Tesseract is not installed on this server."),
        ):
            from app.services.pdf_roster import _parse_page
            result = _parse_page(mock_page, page_number=1)

        assert result.error == "Tesseract is not installed on this server."
        assert result.entries == []

    def test_blank_lines_between_rows_are_ignored(self):
        rows = [
            _header_words(line=0),
            # line 1 is totally empty (no words produced for it — just skip)
            _student_words("1", "12345", "AHMET", "YILMAZ", line=2),
        ]
        result = self._run(rows)
        assert len(result.entries) == 1

    def test_classroom_name_detected_from_title(self):
        rows = [
            [_w("9.", (30.0, 50.0), 0), _w("Sinif", (55.0, 100.0), 0),
             _w("/", (105.0, 115.0), 0), _w("B", (120.0, 135.0), 0),
             _w("Subesi", (140.0, 190.0), 0)],
            _header_words(line=1),
            _student_words("1", "12345", "AHMET", "YILMAZ", line=2),
        ]
        result = self._run(rows)
        assert result.classroom_name == "9B"


# ---------------------------------------------------------------------------
# 7. Integration / smoke test — parse_pdf with a real text-layer PDF
# ---------------------------------------------------------------------------

class TestParsePdfSmoke:
    """Creates a minimal single-page PDF using PyMuPDF's text layer.
    This test verifies that parse_pdf returns PageParseResult objects and
    does not raise exceptions — even when the content cannot be fully parsed.

    These PDFs use a real text layer so OCR is never invoked. _check_tesseract
    is patched to a no-op so the suite runs on machines without Tesseract.
    """

    @pytest.fixture(autouse=True)
    def _patch_tesseract_check(self):
        with patch("app.services.pdf_roster._check_tesseract"):
            yield

    def _minimal_pdf(self) -> bytes:
        doc = fitz.open()
        page = doc.new_page(width=595, height=842)
        page.insert_text((50, 50), "Hello World — not an e-Okul page", fontsize=12)
        return doc.tobytes()

    def test_returns_list_of_page_results(self):
        pdf_bytes = self._minimal_pdf()
        results = parse_pdf(pdf_bytes)
        assert isinstance(results, list)
        assert len(results) == 1

    def test_unrecognised_page_produces_error_not_exception(self):
        pdf_bytes = self._minimal_pdf()
        results = parse_pdf(pdf_bytes)
        page = results[0]
        # The content is not an e-Okul roster so parsing fails gracefully
        assert page.error is not None or page.classroom_name is None
        assert page.page_number == 1

    def test_multipage_pdf_returns_one_result_per_page(self):
        doc = fitz.open()
        for _ in range(3):
            p = doc.new_page(width=595, height=842)
            p.insert_text((50, 50), "page content", fontsize=12)
        pdf_bytes = doc.tobytes()

        results = parse_pdf(pdf_bytes)
        assert len(results) == 3
        assert [r.page_number for r in results] == [1, 2, 3]


# ---------------------------------------------------------------------------
# 8. Feature-detection test — parse_pdf raises when Tesseract is unavailable
# ---------------------------------------------------------------------------

class TestParsePdfOcrUnavailable:
    """Verifies that parse_pdf raises OcrUnavailableError (not a generic
    exception) when _check_tesseract detects a missing binary or language pack,
    so the router can return HTTP 503 with an actionable message.
    """

    def _minimal_pdf(self) -> bytes:
        doc = fitz.open()
        page = doc.new_page(width=595, height=842)
        page.insert_text((50, 50), "Hello World", fontsize=12)
        return doc.tobytes()

    def test_raises_ocr_unavailable_when_binary_missing(self):
        with patch(
            "app.services.pdf_roster._check_tesseract",
            side_effect=OcrUnavailableError(
                "Tesseract OCR is not installed on this server; "
                "image-only PDFs cannot be processed."
            ),
        ):
            with pytest.raises(OcrUnavailableError, match="Tesseract OCR is not installed"):
                parse_pdf(self._minimal_pdf())

    def test_raises_ocr_unavailable_when_tur_pack_missing(self):
        with patch(
            "app.services.pdf_roster._check_tesseract",
            side_effect=OcrUnavailableError(
                "The Tesseract Turkish language pack (tesseract-ocr-tur) is not installed; "
                "image-only PDFs cannot be processed."
            ),
        ):
            with pytest.raises(OcrUnavailableError, match="tesseract-ocr-tur"):
                parse_pdf(self._minimal_pdf())
