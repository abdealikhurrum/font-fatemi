#!/usr/bin/env python3
"""
verb_game.py — Gamified LSD verb data collection.

Presents Urdu verb forms one at a time; you type the LSD equivalent.
Pairs are saved to linguistic/seed/lsd_verb_pairs.json.

Once enough pairs are collected, run:
  python3 verb_game.py --analyse
to see derived suffix-mapping rules and auto-generated LSD candidates.

Usage:
  python3 scripts/verb_game.py           # collect mode
  python3 scripts/verb_game.py --analyse # show derived rules
"""

import argparse
import json
import pathlib
import re
import sys
from collections import defaultdict

ROOT       = pathlib.Path(__file__).parent.parent
VERBS_FILE = ROOT / "seed" / "urdu_verbs.json"
PAIRS_FILE = ROOT / "seed" / "lsd_verb_pairs.json"
TRANS_FILE = ROOT / "transliteration" / "lsd_roman.json"

# ---------------------------------------------------------------------------
# Helpers

def load_trans() -> dict[str, str]:
    if not TRANS_FILE.exists():
        return {}
    data = json.loads(TRANS_FILE.read_text(encoding="utf-8"))
    flat = {}
    for key, val in data.items():
        if key.startswith("_"):
            continue
        if isinstance(val, dict):
            flat.update(val)
        elif isinstance(val, str):
            flat[key] = val
    return flat

def auto_roman(word: str, trans: dict[str, str]) -> str:
    result, i = [], 0
    while i < len(word):
        if i + 1 < len(word) and (m := trans.get(word[i:i+2])):
            result.append(m); i += 2
        elif m := trans.get(word[i]):
            result.append(m); i += 1
        else:
            result.append(word[i]); i += 1
    return "".join(result)

def ask(prompt: str, default: str = "") -> str:
    suffix = f" [{default}]" if default else ""
    try:
        val = input(f"  {prompt}{suffix}: ").strip()
    except (EOFError, KeyboardInterrupt):
        print(); sys.exit(0)
    return val or default

def load_pairs() -> list[dict]:
    PAIRS_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not PAIRS_FILE.exists():
        return []
    return json.loads(PAIRS_FILE.read_text(encoding="utf-8"))

def save_pairs(pairs: list[dict]):
    PAIRS_FILE.write_text(
        json.dumps(pairs, ensure_ascii=False, indent=2), encoding="utf-8"
    )

# ---------------------------------------------------------------------------
# Collect mode

def collect():
    trans  = load_trans()
    verbs  = json.loads(VERBS_FILE.read_text(encoding="utf-8"))
    pairs  = load_pairs()

    # Index existing pairs so we don't re-ask
    done = {(p["urdu_infinitive"], p["urdu_label"]) for p in pairs}
    total_done = len(done)

    # Build queue: all forms not yet answered, in order
    queue = []
    for verb in verbs:
        inf = verb["infinitive"]
        for form in verb["forms"]:
            key = (inf, form["label"])
            if key not in done:
                queue.append((verb, form))

    if not queue:
        print("All forms answered! Run --analyse to see derived rules.")
        return

    total_remaining = len(queue)
    print("━" * 54)
    print("  LSD Verb Pairs — type the LSD equivalent of each form")
    print("  Ctrl-C to quit and save. Skip a form with 's'.")
    print("━" * 54)
    print(f"  {total_done} done, {total_remaining} remaining\n")

    for verb, form in queue:
        inf     = verb["infinitive"]
        meaning = verb["meaning"]
        label   = form["label"]
        u_word  = form["word"]
        u_roman = form["roman"]

        print(f"  ┌─ {inf} ({meaning})")
        print(f"  │  {label}")
        print(f"  └→ Urdu: {u_word}  ({u_roman})")

        lsd_word = ask("  LSD form (Arabic script, 's' to skip)")
        if lsd_word.lower() == "s":
            print("  ↷  Skipped.\n")
            continue
        if not lsd_word:
            print("  ↷  Skipped.\n")
            continue

        suggested = auto_roman(lsd_word, trans)
        lsd_roman = ask("  Roman", default=suggested)

        pair = {
            "urdu_infinitive": inf,
            "urdu_meaning":    meaning,
            "urdu_label":      label,
            "urdu_word":       u_word,
            "urdu_roman":      u_roman,
            "lsd_word":        lsd_word,
            "lsd_roman":       lsd_roman,
        }
        pairs.append(pair)
        save_pairs(pairs)
        total_done += 1
        print(f"  ✓  Saved. ({total_done} total)\n")

    print(f"\n  Session complete. Run --analyse to see derived rules.")

# ---------------------------------------------------------------------------
# Analyse mode — derive suffix-mapping rules from collected pairs

def longest_common_prefix(a: str, b: str) -> str:
    i = 0
    while i < len(a) and i < len(b) and a[i] == b[i]:
        i += 1
    return a[:i]

def derive_suffix_map(pairs: list[dict]) -> dict[str, dict[str, str]]:
    """
    For each pair, compute:
      urdu_suffix  = urdu_word  with the shared prefix stripped
      lsd_suffix   = lsd_word   with the shared prefix stripped
    Group by urdu_suffix → list of lsd_suffixes seen.
    """
    mapping: dict[str, list[str]] = defaultdict(list)
    for p in pairs:
        prefix = longest_common_prefix(p["urdu_word"], p["lsd_word"])
        u_suf  = p["urdu_word"][len(prefix):]
        l_suf  = p["lsd_word"][len(prefix):]
        mapping[u_suf].append(l_suf)

    # Summarise: most common LSD suffix for each Urdu suffix
    result = {}
    for u_suf, l_sufs in mapping.items():
        counts: dict[str, int] = defaultdict(int)
        for s in l_sufs:
            counts[s] += 1
        best = max(counts, key=lambda s: counts[s])
        result[u_suf] = {
            "most_common_lsd_suffix": best,
            "count": counts[best],
            "variants": dict(counts),
        }
    return result

def analyse():
    pairs = load_pairs()
    if not pairs:
        print("No pairs collected yet. Run without --analyse first.")
        return

    print(f"\n  {len(pairs)} pairs collected across "
          f"{len({p['urdu_infinitive'] for p in pairs})} verbs\n")

    rules = derive_suffix_map(pairs)
    if not rules:
        print("  Not enough data to derive rules yet.")
        return

    print("  ── Derived suffix mappings (Urdu → LSD) ──\n")
    print(f"  {'Urdu suffix':<16} {'→  LSD suffix':<20} {'n':>4}  variants")
    print("  " + "─" * 60)
    for u_suf, info in sorted(rules.items(), key=lambda x: -x[1]["count"]):
        u_display = f"ـ{u_suf}" if u_suf else "∅"
        l_display = f"ـ{info['most_common_lsd_suffix']}" if info['most_common_lsd_suffix'] else "∅"
        variants  = "  ".join(
            f"ـ{s}({c})" if s else f"∅({c})"
            for s, c in info["variants"].items()
        )
        print(f"  {u_display:<16}  {l_display:<20} {info['count']:>4}  {variants}")

    # Show which labels are still missing
    verbs  = json.loads(VERBS_FILE.read_text(encoding="utf-8"))
    done   = {(p["urdu_infinitive"], p["urdu_label"]) for p in pairs}
    missing = []
    for verb in verbs:
        for form in verb["forms"]:
            if (verb["infinitive"], form["label"]) not in done:
                missing.append(f"{verb['infinitive']} / {form['label']}")

    if missing:
        print(f"\n  ── {len(missing)} forms still unanswered ──")
        for m in missing[:10]:
            print(f"    {m}")
        if len(missing) > 10:
            print(f"    … and {len(missing) - 10} more")

# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--analyse", action="store_true",
                    help="Show derived suffix-mapping rules")
    args = ap.parse_args()
    if args.analyse:
        analyse()
    else:
        collect()

if __name__ == "__main__":
    main()
