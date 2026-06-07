"""
PDF ingestion.

Two kinds of PDF turn up, and they want opposite treatment:

  1. Born-digital PDFs with a real text layer. The text is usually in the LSD
     *double-press* shorthand (e.g. a space + Arabic semicolon stands in for
     چھے), so we run it through the repo's double_press_convert to recover
     proper Unicode. These pages are gold: the actual page image paired with
     correct text is *real* training data, far better than synthetic. We crop
     each text line from the rendered page and label it with its converted text.

  2. PDFs that are just curves/scanned images, or whose text layer is garbled
     (a legacy non-Unicode font, mojibake). There's no trustworthy text to
     extract, so we don't fabricate a label — the page image goes to an
     OCR/transcription queue instead.

The split is decided per page by how Arabic-script the extracted text is: real
LSD double-press text is dominated by Arabic letters, garbled/Latin-encoded text
is not.
"""

from __future__ import annotations

import pathlib
import sys
from dataclasses import dataclass

import fitz  # PyMuPDF
from PIL import Image

from fonts import REPO_ROOT
from normalize import normalize

# double_press_convert lives at the repo root, not in ocr/.
sys.path.insert(0, str(REPO_ROOT))
from double_press_convert import convert_text  # noqa: E402


@dataclass
class PdfLine:
    """One text line lifted from a born-digital PDF: image crop + true label."""
    image: Image.Image
    text: str
    page: int


@dataclass
class PdfPage:
    """A page with no usable text layer — needs OCR or manual transcription."""
    image: Image.Image
    page: int


@dataclass
class PdfResult:
    lines: list[PdfLine]
    needs_ocr: list[PdfPage]
    n_text_pages: int
    n_image_pages: int


def _is_arabic(ch: str) -> bool:
    o = ord(ch)
    return (
        0x0600 <= o <= 0x06FF      # Arabic
        or 0x0750 <= o <= 0x077F   # Arabic Supplement
        or 0x08A0 <= o <= 0x08FF   # Arabic Extended-A
        or 0xFB50 <= o <= 0xFDFF   # Arabic Presentation Forms-A
        or 0xFE70 <= o <= 0xFEFF   # Arabic Presentation Forms-B
    )


def arabic_fraction(text: str) -> float:
    """Share of *alphabetic* characters that are Arabic-script. Punctuation,
    digits and whitespace are ignored, so page numbers don't skew it."""
    letters = [c for c in text if c.isalpha()]
    if not letters:
        return 0.0
    return sum(1 for c in letters if _is_arabic(c)) / len(letters)


def _pixmap_to_pil(pix: "fitz.Pixmap") -> Image.Image:
    return Image.frombytes("L", (pix.width, pix.height), pix.samples)


def ingest_pdf(
    path: pathlib.Path,
    *,
    dpi: int = 200,
    convert: bool = True,
    min_arabic_frac: float = 0.5,
    min_line_chars: int = 2,
    pad: int = 4,
) -> PdfResult:
    """Extract real (image, text) line pairs from a PDF, routing pages with no
    usable text layer to `needs_ocr`.

    convert:         run double-press → Unicode on extracted text.
    min_arabic_frac: a page's text must be at least this Arabic-script to be
                     trusted; below it the page is treated as image-only.
    """
    scale = dpi / 72.0
    mat = fitz.Matrix(scale, scale)
    lines: list[PdfLine] = []
    needs_ocr: list[PdfPage] = []
    n_text = n_image = 0

    with fitz.open(path) as doc:
        for pno, page in enumerate(doc):
            raw = page.get_text("text")
            if not raw.strip() or arabic_fraction(raw) < min_arabic_frac:
                pix = page.get_pixmap(matrix=mat, colorspace=fitz.csGRAY)
                needs_ocr.append(PdfPage(_pixmap_to_pil(pix), pno))
                n_image += 1
                continue

            n_text += 1
            pix = page.get_pixmap(matrix=mat, colorspace=fitz.csGRAY)
            page_img = _pixmap_to_pil(pix)
            W, H = page_img.size

            info = page.get_text("dict")
            for block in info["blocks"]:
                if block.get("type", 0) != 0:  # 0 = text block; 1 = image
                    continue
                for ln in block["lines"]:
                    text = "".join(span["text"] for span in ln["spans"])
                    if convert:
                        text = convert_text(text)
                    label = normalize(text)
                    if len(label) < min_line_chars:
                        continue
                    x0, y0, x1, y1 = ln["bbox"]
                    box = (
                        max(0, int(x0 * scale) - pad),
                        max(0, int(y0 * scale) - pad),
                        min(W, int(x1 * scale) + pad),
                        min(H, int(y1 * scale) + pad),
                    )
                    if box[2] <= box[0] or box[3] <= box[1]:
                        continue
                    lines.append(PdfLine(page_img.crop(box), label, pno))

    return PdfResult(lines, needs_ocr, n_text, n_image)


def collect_pdfs(paths: list[pathlib.Path]) -> list[pathlib.Path]:
    """Expand a list of files/directories into a sorted list of .pdf files."""
    out: list[pathlib.Path] = []
    for p in paths:
        if p.is_dir():
            out.extend(sorted(p.rglob("*.pdf")))
        elif p.is_file() and p.suffix.lower() == ".pdf":
            out.append(p)
        else:
            raise SystemExit(f"Not a PDF or directory: {p}")
    return out
