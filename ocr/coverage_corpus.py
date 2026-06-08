#!/usr/bin/env python3
"""
Character-coverage corpus generator for Lisan ud-Dawat.

When there is no large real corpus yet, the model can still be taught *every
glyph the fonts can draw* and *every base-letter + iʿrāb combination*, by
synthesising pseudo-words that systematically cover the alphabet. This is a
stop-gap: real text (see TRAINING.md) always beats coverage text for word- and
context-level accuracy, but coverage text guarantees the recogniser has at least
seen each letterform — isolated, initial, medial and final — and each mark.

The letter inventory is taken straight from the **intersection of the body
fonts' cmaps** (so every emitted letter renders in every font, no tofu),
restricted to Arabic-script letters. The iʿrāb marks come from
``normalize.VOCALIZATION_MARKS`` (the same set the rest of the pipeline uses).

Output is a plain UTF-8 file, one line per unit, ready for
``generate.py --corpus``.

    python3 ocr/coverage_corpus.py --out ocr/data/coverage.txt --lines 2000
"""

from __future__ import annotations

import argparse
import pathlib
import unicodedata

from fontTools.ttLib import TTFont

import fonts as font_registry
from normalize import VOCALIZATION_MARKS, normalize

# Arabic-script Unicode blocks that hold *letters* we care about. Presentation
# forms (FB50+, FE70+) are deliberately excluded — those are display glyphs, not
# orthography, and normalize.py would never produce them in a label.
_ARABIC_LETTER_RANGES = (
    (0x0620, 0x063F),  # Arabic letters
    (0x0641, 0x064A),  # Arabic letters (after the harakat gap)
    (0x066E, 0x066F),  # dotless beh / qaf
    (0x0671, 0x06D3),  # extended Arabic / Urdu / Persian letters
    (0x06D5, 0x06D5),  # ae
    (0x06EE, 0x06EF),  # dal/reh variants
    (0x06FA, 0x06FF),  # more extended letters
)


def _is_arabic_letter(cp: int) -> bool:
    if not any(lo <= cp <= hi for lo, hi in _ARABIC_LETTER_RANGES):
        return False
    return unicodedata.category(chr(cp)) == "Lo"


def font_codepoints(path: pathlib.Path) -> set[int]:
    """The set of Unicode codepoints a TTF's cmap can render."""
    font = TTFont(str(path), fontNumber=0, lazy=True)
    cps: set[int] = set()
    for table in font["cmap"].tables:
        cps.update(table.cmap.keys())
    font.close()
    return cps


def renderable_letters(font_ids: list[str] | None) -> list[str]:
    """Arabic letters present in *every* selected font's cmap (sorted)."""
    specs = font_registry.resolve(font_ids)
    common: set[int] | None = None
    for spec in specs:
        cps = {cp for cp in font_codepoints(spec.path) if _is_arabic_letter(cp)}
        common = cps if common is None else (common & cps)
    return [chr(cp) for cp in sorted(common or set())]


def _rng(seed: int):
    import numpy as np
    return np.random.default_rng(seed)


def build_lines(
    letters: list[str],
    marks: list[str],
    *,
    n_lines: int,
    seed: int = 1424,
    words_per_line=(1, 4),
    word_len=(2, 6),
    vocalize_frac: float = 0.5,
    mark_frac: float = 0.5,
) -> list[str]:
    """Synthesise coverage lines.

    Guarantees: (1) every letter appears, in word-medial context so its joining
    forms are exercised; (2) every (letter, mark) pair appears at least once.
    The rest are random pseudo-words, a ``vocalize_frac`` of them carrying marks
    (each eligible base getting one with probability ``mark_frac``).
    """
    rng = _rng(seed)
    lines: list[str] = []

    # (1) joining-form coverage: wrap each letter between two filler letters so
    # it is forced into a medial position (and the fillers cover initial/final).
    filler = letters[0] if letters else ""
    for i in range(0, len(letters), 6):
        chunk = letters[i : i + 6]
        # each letter as: filler+letter+filler (medial), plus the bare letter
        word = "".join(filler + ch + filler for ch in chunk)
        lines.append(" ".join([filler + ch + filler for ch in chunk]))
        lines.append(" ".join(chunk))  # isolated forms

    # (2) every base+mark pair, a handful per line.
    pairs = [base + mk for base in letters for mk in marks]
    for i in range(0, len(pairs), 8):
        lines.append(" ".join(pairs[i : i + 8]))

    # (3) random pseudo-words for bulk volume + n-gram variety.
    def rand_word() -> str:
        n = int(rng.integers(word_len[0], word_len[1] + 1))
        chars: list[str] = []
        voweled = rng.random() < vocalize_frac
        for _ in range(n):
            ch = letters[int(rng.integers(0, len(letters)))]
            chars.append(ch)
            if voweled and marks and rng.random() < mark_frac:
                chars.append(marks[int(rng.integers(0, len(marks)))])
        return "".join(chars)

    while len(lines) < n_lines:
        nw = int(rng.integers(words_per_line[0], words_per_line[1] + 1))
        lines.append(" ".join(rand_word() for _ in range(nw)))

    # Normalise (NFC etc.) and dedup, preserving order.
    seen: set[str] = set()
    out: list[str] = []
    for ln in lines:
        ln = normalize(ln)
        if ln and ln not in seen:
            seen.add(ln)
            out.append(ln)
    return out


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--out", type=pathlib.Path, required=True,
                   help="Where to write the coverage corpus (UTF-8).")
    p.add_argument("--fonts", nargs="*", default=None,
                   help="Font ids whose common cmap defines the alphabet. "
                        f"Default: {' '.join(font_registry.DEFAULT_FONTS)}.")
    p.add_argument("--lines", type=int, default=2000,
                   help="Approximate number of corpus lines to emit.")
    p.add_argument("--seed", type=int, default=1424)
    p.add_argument("--vocalize-frac", type=float, default=0.5,
                   help="Fraction of random pseudo-words that carry iʿrāb.")
    p.add_argument("--include", type=pathlib.Path, default=None,
                   help="Optional real corpus to prepend (its real words are "
                        "always better than pseudo-words).")
    return p.parse_args()


def main() -> None:
    args = parse_args()
    letters = renderable_letters(args.fonts)
    marks = sorted(VOCALIZATION_MARKS)
    if not letters:
        raise SystemExit("No common Arabic letters found across the fonts' cmaps.")

    lines: list[str] = []
    if args.include and args.include.is_file():
        from corpus import load_lines
        lines.extend(load_lines(args.include))

    lines.extend(build_lines(letters, marks, n_lines=args.lines, seed=args.seed,
                             vocalize_frac=args.vocalize_frac))

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Coverage corpus: {len(letters)} letters x {len(marks)} marks "
          f"-> {len(lines)} lines  ->  {args.out}")


if __name__ == "__main__":
    main()
