"""
Ground-truth normalisation.

The single subtlest thing in this whole pipeline: the label we train against
must be *one canonical Unicode spelling* per word. If the corpus contains the
same word spelled two ways (a literal kashida here, a presentation-form ligature
there, marks in a different order), the model is asked to learn a contradiction
and accuracy collapses. Vocalization (the iʿrāb) is only a *nice-to-have* in
Lisan ud-Dawat — plenty of text is written unvocalized — but when the marks are
present they still have to be spelled consistently, or the model learns noise.

This module is deliberately *conservative*. It only fixes things that are
unambiguously presentation, never spelling:

  - NFC: canonical-orders combining marks so identical text compares equal.
  - Strips the tatweel/kashida (U+0640): pure justification decoration, it is
    never part of a word and must not appear in ground truth.
  - Strips bidi control characters and other invisibles.
  - Collapses runs of whitespace.

It intentionally does NOT remap letters (e.g. it will not fold an Urdu yeh into
an Arabic yeh). Those distinctions are real spelling in Lisan ud-Dawat, and the
letter↔letter substitutions in fatemiMaqala.fea / singleiraab.fea are *font
display features*, not orthography. If you decide on house spelling rules (say,
"always U+06CC for final yeh"), add them to CANONICAL_MAP below so the corpus
and the labels agree — that is the right place to encode such a decision.
"""

from __future__ import annotations

import unicodedata

TATWEEL = "ـ"  # ARABIC TATWEEL (kashida)

# Invisible / formatting characters that should never reach a label.
_STRIP = {
    "​",  # zero width space
    "‌",  # zero width non-joiner
    "‍",  # zero width joiner
    "‎",  # left-to-right mark
    "‏",  # right-to-left mark
    "‪",  # LRE
    "‫",  # RLE
    "‬",  # PDF
    "‭",  # LRO
    "‮",  # RLO
    "⁦",  # LRI
    "⁧",  # RLI
    "⁨",  # FSI
    "⁩",  # PDI
    "﻿",  # BOM / ZWNBSP
    TATWEEL,
}

# Vocalization marks (iʿrāb / tashkīl). Removing these yields the unvocalized
# spelling of a word. We treat hamza-above/below (U+0654/U+0655) as orthography,
# not vocalization, and keep them — they sit on a letter's seat and can change
# the word. Everything here is a pure pronunciation mark that LSD text may or may
# not carry. (Matches the harakat in fatemimaqala/iraab.txt.)
VOCALIZATION_MARKS = frozenset(
    "ً"  # fathatan
    "ٌ"  # dammatan
    "ٍ"  # kasratan
    "َ"  # fatha
    "ُ"  # damma
    "ِ"  # kasra
    "ّ"  # shadda
    "ْ"  # sukun
    "ٓ"  # maddah above
    "ٖ"  # subscript alef
    "ٗ"  # inverted damma
    "٘"  # mark noon ghunna
    "ٰ"  # superscript (dagger) alef
)


def strip_vocalization(text: str) -> str:
    """Return `text` with the iʿrāb removed — its unvocalized spelling.

    Used by the generator to render a share of the dataset unvocalized, so the
    recogniser handles plain text as well as fully-voweled text. Run after
    normalize() so combining marks are already NFC-ordered.
    """
    return "".join(ch for ch in text if ch not in VOCALIZATION_MARKS)


# House spelling rules: map any codepoint you consider non-canonical to its
# canonical form. Empty by default on purpose — add entries only when you have
# made a deliberate orthographic decision. Example (commented):
#   "ﻻ": "لا",  # LAM-ALEF presentation form -> lam + alef
CANONICAL_MAP: dict[str, str] = {}


def normalize(text: str) -> str:
    """Return the canonical label form of a line of Lisan ud-Dawat text."""
    text = unicodedata.normalize("NFC", text)
    if CANONICAL_MAP:
        text = text.translate(str.maketrans(CANONICAL_MAP))
    text = "".join(ch for ch in text if ch not in _STRIP)
    # Collapse internal whitespace; trim ends.
    text = " ".join(text.split())
    return text
