"""
Font registry for the OCR synthetic-data generator.

The whole strategy rests on one fact: we own the fonts, so we can render any
Unicode Lisan ud-Dawat text into a perfectly-labelled line image. To make the
recogniser robust to the typefaces real pages use, we render the same corpus in
several faces and let the trainer see all of them.

Paths are resolved relative to the repository root so the generator works no
matter the current working directory.
"""

from __future__ import annotations

import pathlib
from dataclasses import dataclass, field

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent


@dataclass(frozen=True)
class FontSpec:
    """A typeface to render with.

    point_sizes: pixel em-sizes to render at. More sizes = more scale variety,
        which helps the model generalise across scan resolutions.
    language:    BCP-47-ish tag handed to the HarfBuzz shaper. Lisan ud-Dawat
        uses the Arabic script with Urdu/Persian extensions; "ar" gives the
        plainest shaping, which matches how these faces are designed.
    is_display:  display faces (AlFatemi) are for headings, not body text. They
        are off by default but available for title-line variety.
    """

    name: str
    rel_path: str
    point_sizes: tuple[int, ...] = (40, 56, 72)
    language: str = "ar"
    is_display: bool = False

    @property
    def path(self) -> pathlib.Path:
        return REPO_ROOT / self.rel_path

    def exists(self) -> bool:
        return self.path.is_file()


# The three faces real Lisan ud-Dawat pages are typically set in, plus AlFatemi
# for the occasional display/heading line. Body faces are enabled by default.
FONTS: dict[str, FontSpec] = {
    "fatemimaqala": FontSpec(
        name="FatemiMaqala",
        rel_path="fatemimaqala/FatemiMaqala-Regular.ttf",
    ),
    "kanzalmarjaan": FontSpec(
        name="Kanz al-Marjaan",
        rel_path="ocr/fonts/KanzAlMarjaan-Regular.ttf",
    ),
    "alfatemi": FontSpec(
        name="AlFatemi",
        rel_path="alfatemi/AlFatemi-Regular.ttf",
        point_sizes=(64, 88),
        is_display=True,
    ),
}

# What the generator renders unless --fonts overrides it.
DEFAULT_FONTS: tuple[str, ...] = ("fatemimaqala", "kanzalmarjaan")


def resolve(font_ids: list[str] | None) -> list[FontSpec]:
    """Turn a list of ids (or None for the default set) into FontSpecs,
    erroring clearly on unknown ids or missing files."""
    ids = font_ids if font_ids else list(DEFAULT_FONTS)
    specs: list[FontSpec] = []
    for fid in ids:
        if fid not in FONTS:
            raise SystemExit(
                f"Unknown font id '{fid}'. Known: {', '.join(FONTS)}"
            )
        spec = FONTS[fid]
        if not spec.exists():
            raise SystemExit(f"Font file missing for '{fid}': {spec.path}")
        specs.append(spec)
    return specs
