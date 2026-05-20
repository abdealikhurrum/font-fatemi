#!/usr/bin/env python3
"""
seed_entry.py — Interactive CLI for entering LSD seed vocabulary.

Entries are appended to linguistic/seed/lsd_seed.json.
Run with: python3 scripts/seed_entry.py
"""

import json
import pathlib
import sys

SEED_FILE = pathlib.Path(__file__).parent.parent / "seed" / "lsd_seed.json"
TRANS_FILE = pathlib.Path(__file__).parent.parent / "transliteration" / "lsd_roman.json"

CATEGORIES = [
    "pronoun",
    "particle",
    "conjunction",
    "postposition",
    "verb",
    "noun",
    "adjective",
    "adverb",
    "numeral",
    "interjection",
    "other",
]

# ---------------------------------------------------------------------------
# Transliteration (best-effort, character-by-character)

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
    result = []
    i = 0
    while i < len(word):
        if i + 1 < len(word) and (m := trans.get(word[i:i+2])):
            result.append(m); i += 2
        elif m := trans.get(word[i]):
            result.append(m); i += 1
        else:
            result.append(word[i]); i += 1
    return "".join(result)

# ---------------------------------------------------------------------------
# Storage

def load_entries() -> list[dict]:
    SEED_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not SEED_FILE.exists():
        return []
    return json.loads(SEED_FILE.read_text(encoding="utf-8"))

def save_entries(entries: list[dict]):
    SEED_FILE.write_text(
        json.dumps(entries, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )

# ---------------------------------------------------------------------------
# UI helpers

def ask(prompt: str, default: str = "") -> str:
    suffix = f" [{default}]" if default else ""
    try:
        val = input(f"  {prompt}{suffix}: ").strip()
    except (EOFError, KeyboardInterrupt):
        print()
        sys.exit(0)
    return val or default

def pick_category() -> str:
    print("\n  Category:")
    for i, c in enumerate(CATEGORIES, 1):
        print(f"    {i:2}. {c}")
    while True:
        raw = ask("Number")
        try:
            idx = int(raw) - 1
            if 0 <= idx < len(CATEGORIES):
                return CATEGORIES[idx]
        except ValueError:
            pass
        # allow typing the name directly
        if raw.lower() in CATEGORIES:
            return raw.lower()
        print("  Invalid — enter a number or category name.")

def print_summary(entries: list[dict]):
    if not entries:
        return
    by_cat: dict[str, list[str]] = {}
    for e in entries:
        by_cat.setdefault(e["category"], []).append(e["word"])
    print("\n  ── Saved so far ──")
    for cat, words in sorted(by_cat.items()):
        print(f"  {cat}: {' ، '.join(words)}")

# ---------------------------------------------------------------------------
# Verb form collection

def collect_forms(trans: dict[str, str]) -> list[dict]:
    print("  Forms — enter a label then the form. Blank label to finish.")
    forms = []
    while True:
        print()
        label = ask("  Label (e.g. present-m, past-f, imperative)")
        if not label:
            break
        form_word = ask("  Form (Arabic script)")
        if not form_word:
            break
        suggested = auto_roman(form_word, trans)
        form_roman = ask("  Roman", default=suggested)
        forms.append({"label": label, "word": form_word, "roman": form_roman})
        print(f"    + {label}: {form_word} ({form_roman})")
    return forms

# ---------------------------------------------------------------------------
# Main loop

def main():
    trans = load_trans()
    entries = load_entries()

    print("━" * 50)
    print("  LSD Seed Vocabulary Entry")
    print("  Ctrl-C or blank word to quit.")
    print("━" * 50)
    print_summary(entries)

    existing_words = {e["word"] for e in entries}

    while True:
        print()
        word = ask("Word (Arabic script)")
        if not word:
            break

        if word in existing_words:
            print(f"  ↩  '{word}' already in seed — skipping.")
            continue

        # Auto-derive romanization, let user correct it
        suggested_roman = auto_roman(word, trans)
        roman = ask("Roman", default=suggested_roman)

        category = pick_category()

        entry: dict = {"word": word, "roman": roman, "category": category}

        if category == "verb":
            forms = collect_forms(trans)
            if forms:
                entry["forms"] = forms

        example = ask("Example sentence (optional)")
        if example:
            entry["example"] = example

        entries.append(entry)
        existing_words.add(word)
        save_entries(entries)
        print(f"  ✓  Saved ({len(entries)} total)")

    print_summary(entries)
    print(f"\n  Saved to {SEED_FILE}\n")

if __name__ == "__main__":
    main()
