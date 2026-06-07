"""
Corpus loading: turn a UTF-8 text file into clean, line-level training units.

Line-level is the right granularity for connected-script OCR: the recogniser
sees a whole line at once (CTC / seq2seq), which sidesteps the impossible job of
segmenting a joined Arabic baseline with stacked diacritics into characters.

Long paragraphs are chunked to a sane word count so line images stay a
reasonable width; very short fragments are dropped.
"""

from __future__ import annotations

import pathlib

from normalize import normalize


def load_lines(
    path: pathlib.Path,
    max_words: int = 12,
    min_chars: int = 2,
    dedup: bool = True,
) -> list[str]:
    """Read `path` and return normalised line units.

    max_words: split longer source lines into chunks of at most this many words.
    min_chars: drop chunks shorter than this (after normalisation).
    dedup:     drop exact duplicate lines (keeps the dataset from over-weighting
               repeated boilerplate).
    """
    raw = path.read_text(encoding="utf-8")
    out: list[str] = []
    seen: set[str] = set()

    for source_line in raw.splitlines():
        line = normalize(source_line)
        if not line:
            continue
        for chunk in _chunk(line, max_words):
            if len(chunk) < min_chars:
                continue
            if dedup:
                if chunk in seen:
                    continue
                seen.add(chunk)
            out.append(chunk)
    return out


def _chunk(line: str, max_words: int) -> list[str]:
    words = line.split(" ")
    if len(words) <= max_words:
        return [line]
    return [
        " ".join(words[i : i + max_words])
        for i in range(0, len(words), max_words)
    ]
