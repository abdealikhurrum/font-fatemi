#!/usr/bin/env python3
r"""
u_escape.py — two modes:

LOOKUP  (pass text as argument)
  Shows each character on its own line with the Unicode name.
  python3 u_escape.py "فَتْحَة"

FILTER  (pipe a file through — auto-detected when stdin is not a tty)
  Replaces every non-ASCII character (U+0080+) inline; everything else is
  untouched.  The output is valid Swift.
  cat KeyData.swift | python3 u_escape.py > KeyData_fixed.swift

  --annotate / -a   Also append a // comment to each changed line listing
                    the original characters that were replaced, e.g.:
                    cat KeyData.swift | python3 u_escape.py -a > out.swift
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


def filter_escape(text: str, annotate: bool = False) -> str:
    """Replace every non-ASCII character (U+0080+) with \\u{XXXX} in-place.

    With annotate=True, appends '// <original chars>' to each line that
    had replacements so you can see what was swapped out.
    """
    if not annotate:
        out = []
        for ch in text:
            cp = ord(ch)
            out.append(f"\\u{{{cp:04X}}}" if cp >= 0x80 else ch)
        return "".join(out)

    # Annotate mode: process line-by-line
    lines = text.split("\n")
    result = []
    for line in lines:
        out = []
        seen = []           # preserve insertion order, deduplicate
        for ch in line:
            cp = ord(ch)
            if cp >= 0x80:
                out.append(f"\\u{{{cp:04X}}}")
                if ch not in seen:
                    seen.append(ch)
            else:
                out.append(ch)
        escaped = "".join(out)
        if seen:
            escaped += "  // " + " ".join(seen)
        result.append(escaped)
    return "\n".join(result)


def main():
    args = sys.argv[1:]
    annotate = "--annotate" in args or "-a" in args
    args = [a for a in args if a not in ("--annotate", "-a")]

    if args:
        # Lookup mode: argument(s) given — annotate flag is ignored here
        print(lookup(" ".join(args)))
    else:
        # Filter mode: read from stdin
        text = sys.stdin.read()
        sys.stdout.write(filter_escape(text, annotate=annotate))


if __name__ == "__main__":
    main()
