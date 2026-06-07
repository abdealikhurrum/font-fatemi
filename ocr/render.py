"""
Text → image rendering via Pillow + HarfBuzz (libraqm).

raqm is what makes this correct rather than approximate: it applies the font's
own OpenType GSUB/GPOS tables, so the honorific ligatures, the doubled LSD
letter forms, the Urdu/Persian glyphs, and — crucially — the *positioning of the
iʿrāb* all come out exactly as the typeface intends. That is the whole reason to
render with our own fonts instead of scraping images.

Each line is drawn onto an over-sized canvas, then cropped tight to the actual
ink bounding box (which includes tall mark stacks above the baseline and marks
that hang below it) plus a margin. The result is black text on white, mode "L".
"""

from __future__ import annotations

from PIL import Image, ImageDraw, ImageFont, features

if not features.check("raqm"):  # pragma: no cover - environment guard
    raise SystemExit(
        "Pillow was built without libraqm. Arabic shaping and diacritic\n"
        "positioning will be wrong. Install a raqm-enabled Pillow, e.g.:\n"
        "  Debian/Ubuntu: apt-get install libraqm0\n"
        "  macOS (brew):  brew install libraqm\n"
        "then reinstall Pillow (pip install --force-reinstall Pillow)."
    )

_LAYOUT = ImageFont.Layout.RAQM

# Cache loaded fonts: (path, px) -> ImageFont
_font_cache: dict[tuple[str, int], ImageFont.FreeTypeFont] = {}


def _font(path: str, px: int) -> ImageFont.FreeTypeFont:
    key = (path, px)
    if key not in _font_cache:
        _font_cache[key] = ImageFont.truetype(path, px, layout_engine=_LAYOUT)
    return _font_cache[key]


def render_line(
    text: str,
    font_path: str,
    px: int,
    *,
    language: str = "ar",
    padding: int = 12,
) -> Image.Image:
    """Render one line of RTL text to a tightly-cropped grayscale image."""
    font = _font(font_path, px)

    # Measure on a scratch canvas. anchor "la" + direction rtl gives us the true
    # ink box including diacritics that overshoot the em.
    scratch = Image.new("L", (1, 1), 255)
    draw = ImageDraw.Draw(scratch)
    bbox = draw.textbbox(
        (0, 0), text, font=font, direction="rtl", language=language, anchor="la"
    )
    left, top, right, bottom = bbox
    w = max(1, right - left)
    h = max(1, bottom - top)

    img = Image.new("L", (w + 2 * padding, h + 2 * padding), 255)
    draw = ImageDraw.Draw(img)
    # Shift by -left/-top so the ink lands at (padding, padding).
    draw.text(
        (padding - left, padding - top),
        text,
        font=font,
        fill=0,
        direction="rtl",
        language=language,
        anchor="la",
    )
    return img


# Tesseract's LSTM normalises a line to a fixed height then a maxpool downsamples
# the width, so the number of CTC timesteps a line gets is governed by its
# width-to-height *ratio*, not its absolute size. The default ara/tesstrain net
# is `[1,48,0,1 Ct3,3,16 Mp3,3 ...]`: height is normalised to 48 and Mp3,3 divides
# width by 3, giving roughly `48/3 = 16 * (width/height)` timesteps.
_NET_HEIGHT = 48
_NET_WIDTH_POOL = 3
_TIMESTEPS_PER_RATIO = _NET_HEIGHT / _NET_WIDTH_POOL  # = 16


def min_ctc_width(n_labels: int, height: int, *, factor: float = 2.5) -> int:
    """Smallest image width that gives a label of `n_labels` unichars enough CTC
    timesteps at the given image `height`.

    CTC needs at least one timestep per target label (more when equal labels are
    adjacent, since a blank must separate them). `factor` keeps a safety margin
    above that floor — empirically, clean dense lines pass around 2.3x and fail
    below, so 2.5x is safely clear even after augmentation.
    """
    if n_labels <= 0:
        return 0
    return int(round(factor * n_labels / _TIMESTEPS_PER_RATIO * height))


def pad_to_min_width(img: Image.Image, n_labels: int, *, factor: float = 2.5) -> Image.Image:
    """Pad `img` with white columns until it has enough CTC timesteps for a label
    of `n_labels` unichars.

    Diacritic-dense Lisan ud-Dawat lines have tall iʿrāb stacks, which inflate
    the image height and so *shrink* the width/height ratio — starving the LSTM
    of timesteps and triggering "Compute CTC targets failed", which drops the
    sample from training. Padding adds blank timesteps without distorting any
    glyph or changing the label, so the densest (and most valuable) voweled
    samples survive instead of being silently skipped.
    """
    min_w = min_ctc_width(n_labels, img.height, factor=factor)
    if img.width >= min_w:
        return img
    out = Image.new("L", (min_w, img.height), 255)
    out.paste(img, ((min_w - img.width) // 2, 0))
    return out
