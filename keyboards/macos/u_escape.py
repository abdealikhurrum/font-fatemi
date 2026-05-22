#!/usr/bin/env python3
r"""
u_escape.py — two modes:

LOOKUP  (pass text as argument)
  Shows each character on its own line with the Unicode name.
  python3 u_escape.py "فَتْحَة"

FILTER  (pipe a file through — auto-detected when stdin is not a tty)
  Replaces every non-ASCII character inline; everything else is untouched.
  cat KeyData.swift | python3 u_escape.py > KeyData_fixed.swift
  python3 u_escape.py < KeyData.swift > KeyData_fixed.swift
"""

import sys
import unicodedata


def lookup(text: str) -> str:
    """Per-character breakdown with Unicode names."""
    parts = []
    for ch in text:
        cp = ord(ch)
        if cp > 0x7E or cp < 0x20:
            name = unicodedata.name(ch, "")
            parts.append(f"\\u{{{cp:04X}}}  // {name}")
        else:
            parts.append(repr(ch))
    return "\n".join(parts)


def filter_escape(text: str) -> str:
    """Replace every non-ASCII character (U+0080 and above) with \\u{XXXX} in-place."""
    out = []
    for ch in text:
        cp = ord(ch)
        if cp >= 0x80:
            out.append(f"\\u{{{cp:04X}}}")
        else:
            out.append(ch)
    return "".join(out)


def main():
    if len(sys.argv) > 1:
        # Lookup mode: argument(s) given
        text = " ".join(sys.argv[1:])
        print(lookup(text))
    else:
        # Filter mode: read from stdin (piped or redirected)
        text = sys.stdin.read()
        sys.stdout.write(filter_escape(text))


if __name__ == "__main__":
    main()
