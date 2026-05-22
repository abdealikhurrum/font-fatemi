#!/usr/bin/env python3
r"""
u_escape.py — convert Arabic (or any Unicode) characters to Swift \u{XXXX} escapes.

Usage:
  echo "فتحة" | python3 u_escape.py
  python3 u_escape.py "فتحة كسرة ضمة"
  python3 u_escape.py          # interactive: type/paste, then Ctrl-D
"""

import sys
import unicodedata


def escape(text: str) -> str:
    parts = []
    for ch in text:
        cp = ord(ch)
        if cp > 0x7E or cp < 0x20:          # non-ASCII or control char
            name = unicodedata.name(ch, "")
            parts.append(f"\\u{{{cp:04X}}}  // {name}")
        else:
            parts.append(repr(ch))           # plain ASCII, just show it
    return "\n".join(parts)


def main():
    if len(sys.argv) > 1:
        text = " ".join(sys.argv[1:])
    else:
        text = sys.stdin.read()

    text = text.rstrip("\n")
    if not text:
        print("(empty input)", file=sys.stderr)
        return

    print(escape(text))


if __name__ == "__main__":
    main()
