#!/usr/bin/env python3
"""
fetch_corpora.py — Download open-source Urdu and Gujarati word frequency data
and emit cleaned wordlists suitable for LSD autocomplete.

Sources:
  Urdu   — UrduHack (MIT) word frequency list
             https://github.com/urduhack/urdu-words
  Gujarati — AI4Bharat IndicNLP (MIT) token frequency list
             https://github.com/ai4bharat/IndicNLP-corpus

Usage:
  python3 fetch_corpora.py [--urdu] [--gujarati] [--all]

Output:
  linguistic/wordlist/urdu_raw.txt       one word per line, sorted by frequency
  linguistic/wordlist/gujarati_raw.txt
"""

import argparse
import pathlib
import sys
import urllib.request
import zipfile
import io

OUT = pathlib.Path(__file__).parent.parent / "wordlist"
OUT.mkdir(exist_ok=True)

# ---------------------------------------------------------------------------
# Urdu

URDU_WORDS_URL = (
    "https://raw.githubusercontent.com/urduhack/urdu-words/master/words.txt"
)

def fetch_urdu():
    print("Fetching Urdu word list from urduhack/urdu-words …")
    try:
        with urllib.request.urlopen(URDU_WORDS_URL, timeout=30) as r:
            text = r.read().decode("utf-8")
    except Exception as e:
        print(f"  ERROR: {e}", file=sys.stderr)
        return

    words = [w.strip() for w in text.splitlines() if w.strip()]
    # deduplicate while preserving order
    seen = set()
    unique = [w for w in words if not (w in seen or seen.add(w))]

    out_path = OUT / "urdu_raw.txt"
    out_path.write_text("\n".join(unique), encoding="utf-8")
    print(f"  Saved {len(unique)} words → {out_path}")

# ---------------------------------------------------------------------------
# Gujarati

# AI4Bharat IndicNLP provides per-language token frequency files.
# The Gujarati file is a two-column TSV: <token>\t<frequency>
GUJARATI_FREQ_URL = (
    "https://raw.githubusercontent.com/ai4bharat/IndicNLPSuite/master/"
    "indicnlp_corpus/wordfreq/gu.freq"
)

def fetch_gujarati():
    print("Fetching Gujarati word frequencies from AI4Bharat IndicNLP …")
    try:
        with urllib.request.urlopen(GUJARATI_FREQ_URL, timeout=30) as r:
            text = r.read().decode("utf-8")
    except Exception as e:
        print(f"  ERROR: {e}", file=sys.stderr)
        print("  Trying fallback URL …")
        _fetch_gujarati_fallback()
        return

    pairs = []
    for line in text.splitlines():
        parts = line.strip().split("\t")
        if len(parts) >= 2:
            try:
                pairs.append((parts[0], int(parts[1])))
            except ValueError:
                pass

    pairs.sort(key=lambda x: x[1], reverse=True)
    words = [p[0] for p in pairs]

    out_path = OUT / "gujarati_raw.txt"
    out_path.write_text("\n".join(words), encoding="utf-8")
    print(f"  Saved {len(words)} words → {out_path}")

def _fetch_gujarati_fallback():
    """
    Fallback: fetch from SNLTR / iNLTK Gujarati wordlist.
    This is a plain word-per-line file.
    """
    FALLBACK = (
        "https://raw.githubusercontent.com/goru001/inltk/master/"
        "inltk/data/gu/vocab.txt"
    )
    try:
        with urllib.request.urlopen(FALLBACK, timeout=30) as r:
            text = r.read().decode("utf-8")
        words = [w.strip() for w in text.splitlines() if w.strip()]
        out_path = OUT / "gujarati_raw.txt"
        out_path.write_text("\n".join(words), encoding="utf-8")
        print(f"  Saved {len(words)} words via fallback → {out_path}")
    except Exception as e:
        print(f"  Fallback also failed: {e}", file=sys.stderr)
        print("  Run scripts/build_lsd_wordlist.py --skip-gujarati to proceed without it.")

# ---------------------------------------------------------------------------
# CLI

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--urdu",     action="store_true")
    ap.add_argument("--gujarati", action="store_true")
    ap.add_argument("--all",      action="store_true")
    args = ap.parse_args()

    if args.all or not (args.urdu or args.gujarati):
        fetch_urdu()
        fetch_gujarati()
    else:
        if args.urdu:     fetch_urdu()
        if args.gujarati: fetch_gujarati()

if __name__ == "__main__":
    main()
