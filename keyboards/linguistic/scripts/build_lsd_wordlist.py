#!/usr/bin/env python3
"""
build_lsd_wordlist.py — Derive a frequency-ranked LSD wordlist from multiple sources.

Sources (in priority order):
  1. urdu_freq_raw.txt    — FrequencyWords Urdu, format: "word count" per line
  2. arabic_freq_raw.txt  — FrequencyWords Arabic, same format
  3. persian_freq_raw.txt — FrequencyWords Persian, same format
  4. urdu_raw.txt         — UrduHack full word list (alpha-sorted, no freq)
  5. gujarati_raw.txt     — Gujarati words transliterated to Arabic script

Pipeline:
  - Strip diacritics; keep only Arabic-script words ≥ 2 chars
  - Merge by frequency score; Urdu > Arabic > Persian > plain lists
  - Emit lsd_wordlist.txt: one word per line, highest-frequency first

Usage:
  python3 build_lsd_wordlist.py [--limit N]
"""

import argparse
import json
import pathlib
import re

ROOT  = pathlib.Path(__file__).parent.parent
WLIST = ROOT / "wordlist"
TRANS = ROOT / "transliteration"

# ---------------------------------------------------------------------------
# Helpers

ARABIC_BLOCK_RE = re.compile(r"^[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿‌‍]+$")

DIACRITICS = frozenset(
    "ًٌٍَُِّْ"
    "ٰٕٖٓٔٗؕؖ"
    "ؘؙؚؗ"
)

def strip_diacritics(w: str) -> str:
    return "".join(c for c in w if c not in DIACRITICS)

def is_arabic_script(w: str) -> bool:
    return len(w) >= 2 and bool(ARABIC_BLOCK_RE.match(w))

# ---------------------------------------------------------------------------
# Loaders

def load_freq_file(path: pathlib.Path, weight: float) -> list[tuple[str, float]]:
    """Load a 'word count' file; return (word, weighted_score) pairs."""
    if not path.exists():
        print(f"  SKIP {path.name} — not found (run fetch_corpora.py first)")
        return []
    pairs: list[tuple[str, float]] = []
    max_count = 1
    raw: list[tuple[str, int]] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.strip().split()
        if len(parts) < 2:
            continue
        word = strip_diacritics(parts[0])
        if not is_arabic_script(word):
            continue
        try:
            count = int(parts[1])
        except ValueError:
            continue
        raw.append((word, count))
        if count > max_count:
            max_count = count
    for word, count in raw:
        pairs.append((word, weight * count / max_count))
    print(f"  {len(pairs):>8,} words from {path.name}")
    return pairs

def load_plain_file(path: pathlib.Path, weight: float) -> list[tuple[str, float]]:
    """Load a plain word-per-line file; assign decreasing scores."""
    if not path.exists():
        print(f"  SKIP {path.name} — not found")
        return []
    words = []
    for line in path.read_text(encoding="utf-8").splitlines():
        w = strip_diacritics(line.strip())
        if is_arabic_script(w):
            words.append(w)
    n = len(words)
    pairs = [(w, weight * (1.0 - i / max(n, 1))) for i, w in enumerate(words)]
    print(f"  {len(pairs):>8,} words from {path.name}")
    return pairs

# ---------------------------------------------------------------------------
# Gujarati

def load_gujarati_bridge() -> dict[str, str]:
    path = TRANS / "gujarati_bridge.json"
    if not path.exists():
        return {}
    raw = json.loads(path.read_text(encoding="utf-8"))
    flat: dict[str, str] = {}
    for key, value in raw.items():
        if key.startswith("_"):
            continue
        if isinstance(value, dict):
            flat.update(value)
    return flat

GUJARATI_RE = re.compile(r"^[઀-૿]+$")

def transliterate_gujarati(word: str, bridge: dict[str, str]) -> str | None:
    result = []
    i = 0
    while i < len(word):
        if i + 1 < len(word) and (m := bridge.get(word[i:i+2])):
            result.append(m); i += 2
        elif m := bridge.get(word[i]):
            result.append(m); i += 1
        else:
            return None
    return "".join(result) or None

def load_gujarati(path: pathlib.Path, weight: float) -> list[tuple[str, float]]:
    if not path.exists():
        print(f"  SKIP {path.name} — not found")
        return []
    bridge = load_gujarati_bridge()
    if not bridge:
        print(f"  SKIP {path.name} — gujarati_bridge.json missing")
        return []
    words = []
    for line in path.read_text(encoding="utf-8").splitlines():
        w = line.strip()
        if not w or not GUJARATI_RE.match(w) or len(w) < 2:
            continue
        arabic = transliterate_gujarati(w, bridge)
        if arabic and is_arabic_script(arabic):
            words.append(arabic)
    n = len(words)
    pairs = [(w, weight * (1.0 - i / max(n, 1))) for i, w in enumerate(words)]
    print(f"  {len(pairs):>8,} transliterated words from {path.name}")
    return pairs

# ---------------------------------------------------------------------------
# Merge

def merge(all_pairs: list[tuple[str, float]], limit: int) -> list[str]:
    scores: dict[str, float] = {}
    for word, score in all_pairs:
        scores[word] = scores.get(word, 0.0) + score
    ranked = sorted(scores, key=lambda w: scores[w], reverse=True)
    return ranked[:limit] if limit else ranked

# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--limit", type=int, default=0, help="Keep top N words (0 = all)")
    args = ap.parse_args()

    print("Loading sources …")
    all_pairs: list[tuple[str, float]] = []
    # Higher weight = more influence on final rank
    all_pairs += load_freq_file(WLIST / "urdu_freq_raw.txt",    weight=1.0)
    all_pairs += load_freq_file(WLIST / "arabic_freq_raw.txt",  weight=0.4)
    all_pairs += load_freq_file(WLIST / "persian_freq_raw.txt", weight=0.3)
    all_pairs += load_plain_file(WLIST / "urdu_raw.txt",        weight=0.2)
    all_pairs += load_gujarati(WLIST / "gujarati_raw.txt",      weight=0.15)

    print("\nMerging …")
    merged = merge(all_pairs, args.limit)

    out = WLIST / "lsd_wordlist.txt"
    out.write_text("\n".join(merged), encoding="utf-8")
    print(f"Wrote {len(merged):,} words → {out}")

if __name__ == "__main__":
    main()
