"""Parses e-Okul style class-list PDFs into per-page roster data.

Each page is either a real text layer (rare) or, as with e-Okul's own export,
a scanned image with no text layer at all. Either way we reduce the page to a
flat list of words with pixel/point positions, then reconstruct the table by
clustering the header row's words into columns (S.No | Öğrenci No | Adı |
Soyadı | Cinsiyeti | Pansiyon Durum) and bucketing every later row's words
into those same column ranges. This is far more robust than splitting on
whitespace, since OCR output does not reliably preserve the original
document's column alignment as runs of spaces.
"""

import re
from dataclasses import dataclass, field

import fitz  # pymupdf
import pytesseract
from PIL import Image

from app.services.roster import RosterEntryInput

_MIN_TEXT_LAYER_CHARS = 20
_OCR_DPI = 300
_COLUMN_GAP_FRACTION = 0.025  # min horizontal gap (as a fraction of page width) that separates two columns

_TURKISH_FOLD = str.maketrans(
    {
        "ç": "c", "Ç": "c", "ğ": "g", "Ğ": "g", "ı": "i", "I": "i", "İ": "i",
        "ö": "o", "Ö": "o", "ş": "s", "Ş": "s", "ü": "u", "Ü": "u",
    }
)


def _fold(text: str) -> str:
    """Lowercases and strips Turkish diacritics so header/title matching
    survives both real text and OCR mangling of ğ/ş/ı/ö/ü/ç.
    """
    return text.translate(_TURKISH_FOLD).lower()


@dataclass
class _Word:
    text: str
    left: float
    right: float
    line_key: tuple


@dataclass
class PageParseResult:
    page_number: int
    classroom_name: str | None = None
    entries: list[RosterEntryInput] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    error: str | None = None


class OcrUnavailableError(Exception):
    pass


def _words_from_text_layer(page: "fitz.Page") -> list[_Word]:
    words = []
    for x0, y0, x1, y1, text, block_no, line_no, _word_no in page.get_text("words"):
        stripped = text.strip()
        if stripped:
            words.append(_Word(text=stripped, left=x0, right=x1, line_key=(block_no, line_no)))
    return words


def _words_from_ocr(page: "fitz.Page") -> tuple[list[_Word], float]:
    pix = page.get_pixmap(dpi=_OCR_DPI)
    image = Image.frombytes("RGB", (pix.width, pix.height), pix.samples)
    try:
        data = pytesseract.image_to_data(image, lang="tur", output_type=pytesseract.Output.DICT)
    except pytesseract.TesseractNotFoundError as exc:
        raise OcrUnavailableError("Tesseract is not installed on this server.") from exc

    words = []
    for i, text in enumerate(data["text"]):
        stripped = text.strip()
        if not stripped:
            continue
        left = float(data["left"][i])
        line_key = (data["block_num"][i], data["par_num"][i], data["line_num"][i])
        words.append(_Word(text=stripped, left=left, right=left + float(data["width"][i]), line_key=line_key))
    return words, float(pix.width)


def _get_words_and_width(page: "fitz.Page") -> tuple[list[_Word], float]:
    """Returns (words, page_width). Falls back to OCR only when the page has
    no usable text layer — this is what makes a scanned e-Okul export work.
    """
    if len(page.get_text().strip()) >= _MIN_TEXT_LAYER_CHARS:
        return _words_from_text_layer(page), page.rect.width
    return _words_from_ocr(page)


def _group_lines(words: list[_Word]) -> list[list[_Word]]:
    lines: dict[tuple, list[_Word]] = {}
    order: list[tuple] = []
    for word in words:
        if word.line_key not in lines:
            lines[word.line_key] = []
            order.append(word.line_key)
        lines[word.line_key].append(word)
    return [sorted(lines[key], key=lambda w: w.left) for key in order]


def _line_text(line: list[_Word]) -> str:
    return " ".join(w.text for w in line)


def _cluster_columns(header_line: list[_Word], page_width: float) -> list[tuple[float, float]]:
    """Groups the header row's words into column clusters by horizontal gap,
    then returns each column's [start, end) boundary as the midpoint between
    it and its neighbors (so a slightly misaligned data word still lands in
    the right bucket).
    """
    threshold = page_width * _COLUMN_GAP_FRACTION
    clusters: list[list[_Word]] = []
    for word in header_line:
        if clusters and word.left - clusters[-1][-1].right <= threshold:
            clusters[-1].append(word)
        else:
            clusters.append([word])

    bounds = []
    for i, cluster in enumerate(clusters):
        left_edge = 0.0 if i == 0 else (clusters[i - 1][-1].right + cluster[0].left) / 2
        right_edge = (
            page_width if i == len(clusters) - 1 else (cluster[-1].right + clusters[i + 1][0].left) / 2
        )
        bounds.append((left_edge, right_edge))
    return bounds


def _assign_column(word: _Word, bounds: list[tuple[float, float]]) -> int | None:
    center = (word.left + word.right) / 2
    for i, (start, end) in enumerate(bounds):
        if start <= center < end:
            return i
    return None


def parse_classroom_name(text: str) -> str | None:
    """Finds a title like 'AL - 9. Sınıf / A Şubesi (ALANI YOK) Sınıf Listesi'
    and returns the classroom name it identifies, e.g. '9A'.
    """
    folded = _fold(text)
    # OCR frequently misreads dotless ı as almost anything (1, l, a, ...),
    # even with the Turkish language pack, so "Sınıf" is matched as s.n.f
    # (wildcards for the two ı positions) rather than literally.
    match = re.search(r"(\d{1,2})\s*\.\s*s.n.f\s*/\s*([a-z])\s*subesi", folded)
    if not match:
        return None
    grade, section = match.groups()
    return f"{grade}{section.upper()}"


def _parse_page(page: "fitz.Page", page_number: int) -> PageParseResult:
    result = PageParseResult(page_number=page_number)

    try:
        words, page_width = _get_words_and_width(page)
    except OcrUnavailableError as exc:
        result.error = str(exc)
        return result

    lines = _group_lines(words)
    full_text = "\n".join(_line_text(line) for line in lines)
    result.classroom_name = parse_classroom_name(full_text)

    header_idx = next(
        (i for i, line in enumerate(lines) if "ogrenci" in _fold(_line_text(line)) and "no" in _fold(_line_text(line))),
        None,
    )
    if header_idx is None:
        result.error = "Could not find the 'Öğrenci No' column header on this page."
        return result

    bounds = _cluster_columns(lines[header_idx], page_width)
    if len(bounds) < 4:
        result.error = "Could not identify the table columns (S.No / Öğrenci No / Adı / Soyadı) on this page."
        return result

    school_id_col, name_col, surname_col = 1, 2, 3

    for line in lines[header_idx + 1 :]:
        line_text = _fold(_line_text(line))
        if "ogrenci" in line_text and "sayisi" in line_text:
            break  # hit the "Kız/Erkek/Toplam Öğrenci Sayısı" footer

        buckets: dict[int, list[str]] = {}
        for word in line:
            col = _assign_column(word, bounds)
            if col is not None:
                buckets.setdefault(col, []).append(word.text)

        school_id = " ".join(buckets.get(school_id_col, [])).strip()
        name = " ".join(buckets.get(name_col, [])).strip()
        surname = " ".join(buckets.get(surname_col, [])).strip()

        if not school_id and not name and not surname:
            continue  # blank line
        if not school_id.isdigit() or not name or not surname:
            result.warnings.append(f"Skipped an unreadable row: {_line_text(line)!r}")
            continue

        result.entries.append(RosterEntryInput(name=name, surname=surname, school_id=int(school_id)))

    if not result.entries:
        result.error = result.error or "No student rows could be read on this page."

    return result


def parse_pdf(file_bytes: bytes) -> list[PageParseResult]:
    results = []
    with fitz.open(stream=file_bytes, filetype="pdf") as doc:
        for i, page in enumerate(doc):
            results.append(_parse_page(page, page_number=i + 1))
    return results
