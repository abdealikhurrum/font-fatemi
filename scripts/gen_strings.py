#!/usr/bin/env python3
"""
Convert Localizable.md → Xcode .strings files for each language.

Usage:
    python3 scripts/gen_strings.py

Input:  keyboards/ios/LisanUdDawat/Localizable.md
Output: keyboards/ios/LisanUdDawat/<lang>.lproj/Localizable.strings
        for every language column found in the table header.

Table format (markdown pipe table):
    | key           | en          | lsd         |
    |---------------|-------------|-------------|
    | settings.done | Done        | ختم         |

Rules:
  - Rows whose key starts with # are section comments — skipped.
  - A cell containing only - or [TODO] is treated as untranslated;
    that key is omitted from that language's output file.
  - \n in a cell is written as a literal newline in the .strings value.
  - %d, %@, %.2f etc. pass through unchanged (use for format strings).
"""

import pathlib, re, sys, textwrap

ROOT      = pathlib.Path(__file__).parent.parent
MD_FILE   = ROOT / "keyboards/ios/LisanUdDawat/Localizable.md"
LPROJ_DIR = ROOT / "keyboards/ios/LisanUdDawat"

SKIP_VALUES = {"", "-", "[todo]"}

def parse_table(text: str):
    """Return list of dicts keyed by column header."""
    rows   = []
    header = None
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            header = None   # reset between tables
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        # Separator row — every cell is only dashes, colons, spaces (|---|:---:|)
        if all(re.fullmatch(r"[-: ]*", c) for c in cells):
            continue
        if header is None:
            header = [c.lower() for c in cells]
            continue
        if len(cells) < len(header):
            cells += [""] * (len(header) - len(cells))
        rows.append(dict(zip(header, cells)))
    return rows

def unescape(value: str) -> str:
    return value.replace("\\n", "\n")

def strings_line(key: str, value: str) -> str:
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{key}" = "{escaped}";\n'

def main():
    if not MD_FILE.exists():
        sys.exit(f"ERROR: {MD_FILE} not found")

    text = MD_FILE.read_text(encoding="utf-8")
    rows = parse_table(text)

    if not rows:
        sys.exit("ERROR: no table rows found in Localizable.md")

    # Collect language columns (everything except 'key')
    sample   = rows[0]
    langs    = [k for k in sample.keys() if k != "key"]
    counters = {lang: 0 for lang in langs}

    # Build per-language output
    buffers = {lang: [] for lang in langs}
    for row in rows:
        key = row.get("key", "").strip()
        if not key or key.startswith("#"):
            continue
        for lang in langs:
            val = row.get(lang, "").strip()
            if val.lower() in SKIP_VALUES:
                continue
            buffers[lang].append(strings_line(key, unescape(val)))
            counters[lang] += 1

    # Write files
    for lang, lines in buffers.items():
        out_dir = LPROJ_DIR / f"{lang}.lproj"
        out_dir.mkdir(parents=True, exist_ok=True)
        out_file = out_dir / "Localizable.strings"
        out_file.write_text("".join(lines), encoding="utf-8")
        print(f"  {lang:6s}  {counters[lang]:4d} strings  →  {out_file.relative_to(ROOT)}")

    print(f"\nDone. {sum(counters.values())} total string entries written.")

if __name__ == "__main__":
    main()
