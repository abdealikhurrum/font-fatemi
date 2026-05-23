"""
LSD keyboard layout data for Linux/IBus.

Key mappings are derived from the LSD Mac keylayout and match the
iOS/macOS/Android/Windows implementations. X11 hardware keycodes
(Linux evdev scancode + 8) are used so the engine works regardless
of the X11 keyboard layout active on the system.

Mac virtual keycode → physical key → X11 keycode mapping:
  Mac 0=A(38)  1=S(39)  2=D(40)  3=F(41)  4=H(43)  5=G(42)
      6=Z(52)  7=X(53)  8=C(54)  9=V(55) 11=B(56)
     12=Q(24) 13=W(25) 14=E(26) 15=R(27) 16=Y(29) 17=T(28)
     30=](35) 31=O(32) 32=U(30) 33=[(34) 34=I(31) 35=P(33)
     37=L(46) 38=J(44) 39='(48) 40=K(45) 41=;(47)
     45=N(57) 46=M(58) 50=`(49)
"""

from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional


@dataclass
class KeyData:
    primary: str
    secondary: str = ""           # double-press inserts this
    alternates: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Double-press secondaries
#
# Official LSD rules (lsd.kmn):  سس→ے  ضض→ٹ  طط→ں  ظظ→ہ  حح→چ  ثث→پ  كك→گ
# Extended:                       اا→اٰ  هه→ھ  يي→ئ  رر→ڑ  دد→ڈ  ةة→ۃ  جج→چھے
# ---------------------------------------------------------------------------

_LSD_SECONDARIES: dict[str, str] = {
    "ض": "ٹ",   "ث": "پ",   "ه": "ھ",   "ح": "چ",
    "ج": "چھے", "س": "ے",   "ي": "ئ",   "ا": "اٰ",
    "ك": "گ",   "ط": "ں",   "ر": "ڑ",   "ة": "ۃ",
    "د": "ڈ",   "ظ": "ہ",
}


def secondary_for(char: str) -> Optional[str]:
    return _LSD_SECONDARIES.get(char) or None


# ---------------------------------------------------------------------------
# X11 hardware keycode → LSD character layers
# ---------------------------------------------------------------------------

# Normal layer (no modifier)
NORMAL_LAYER: dict[int, str] = {
    # Row 1 — Q…P + brackets
    24: "ض",   # Q
    25: "ص",   # W
    26: "ث",   # E
    27: "ق",   # R
    28: "ف",   # T
    29: "غ",   # Y
    30: "ع",   # U
    31: "ه",   # I
    32: "خ",   # O
    33: "ح",   # P
    34: "ج",   # [
    35: "ة",   # ]
    # Row 2 — A…L + ;  '
    38: "ش",   # A
    39: "س",   # S
    40: "ي",   # D
    41: "ب",   # F
    42: "ل",   # G
    43: "ا",   # H
    44: "ت",   # J
    45: "ن",   # K
    46: "م",   # L
    47: "ك",   # ;
    48: "؛",   # '
    # Row 3 — Z…M + , .
    52: "ظ",   # Z
    53: "ط",   # X
    54: "ذ",   # C
    55: "د",   # V
    56: "ز",   # B
    57: "ر",   # N
    58: "و",   # M
    59: "،",   # ,  → Arabic comma
    49: "ـ",   # `  → tatweel
    # Digits → Eastern Arabic-Indic numerals
    10: "١",   # 1
    11: "٢",   # 2
    12: "٣",   # 3
    13: "٤",   # 4
    14: "٥",   # 5
    15: "٦",   # 6
    16: "٧",   # 7
    17: "٨",   # 8
    18: "٩",   # 9
    19: "٠",   # 0
}

# Shift layer
SHIFT_LAYER: dict[int, str] = {
    # Row 1
    24: "َ",   # Q+Shift → fatha        (◌َ)
    25: "ً",   # W+Shift → tanwin fath  (◌ً)
    26: "ِ",   # E+Shift → kasra        (◌ِ)
    27: "ٍ",   # R+Shift → tanwin kasr  (◌ٍ)
    28: "ُ",   # T+Shift → damma        (◌ُ)
    29: "ٌ",   # Y+Shift → tanwin damm  (◌ٌ)
    30: "ْ",   # U+Shift → sukun        (◌ْ)
    31: "ّ",   # I+Shift → shadda       (◌ّ)
    32: "ْ",   # O+Shift → sukun (duplicate, per macOS layer)
    33: "[",        # P+Shift → [
    34: "}",        # [+Shift
    35: "{",        # ]+Shift
    # Row 2
    38: "»",        # A+Shift
    39: "«",        # S+Shift
    40: "ى",        # D+Shift → alef maqsura
    43: "آ",        # H+Shift → alef madda
    44: "\"",       # J+Shift
    45: "٫",   # K+Shift → Arabic decimal separator
    46: "٬",   # L+Shift → Arabic thousands separator
    47: ":",        # ;+Shift
    48: "\"",       # '+Shift
    # Row 3
    52: "’",   # Z+Shift → right single quotation mark
    54: "ئ",        # C+Shift → yeh with hamza above
    55: "ء",        # V+Shift → hamza
    56: "أ",        # B+Shift → alef with hamza above
    57: "إ",        # N+Shift → alef with hamza below
    58: "ؤ",        # M+Shift → waw with hamza above
    59: ">",        # ,+Shift
    60: "<",        # .+Shift
    61: "؟",        # /+Shift → Arabic question mark
    51: "|",        # \+Shift
    20: "ـ",   # -+Shift → tatweel (alternate access)
    21: "+",        # =+Shift
    # Shifted digits
    10: "!",
    11: "@",
    12: "#",
    13: "$",
    14: "٪",   # 5+Shift → ٪ (Arabic percent sign)
    15: "^",
    16: "&",
    17: "*",
    18: ")",
    19: "(",
}

# Alt (Option) layer — extended LSD and Urdu characters
ALT_LAYER: dict[int, str] = {
    # Row 1
    24: "‘",   # Q+Alt → left single quotation mark
    25: "’",   # W+Alt → right single quotation mark
    26: "“",   # E+Alt → left double quotation mark
    27: "”",   # R+Alt → right double quotation mark
    28: "ڤ",        # T+Alt
    29: "ٗ",   # Y+Alt
    30: "ؑ",   # U+Alt
    31: "ھ",        # I+Alt → do chashmi he
    32: "ہ",        # O+Alt → he goal
    33: "چ",        # P+Alt
    34: "چ",        # [+Alt
    35: "ۃ",        # ]+Alt
    # Row 2
    38: "ؔ",   # A+Alt
    39: "ے",        # S+Alt → yeh barree
    40: "ی",        # D+Alt → Farsi yeh
    41: "پ",        # F+Alt
    42: "ٓ",   # G+Alt → maddah above
    43: "ٰ",   # H+Alt → superscript alef (kharo zabar)
    44: "ٹ",        # J+Alt → do chashmi te
    45: "ں",        # K+Alt → noon ghunna
    47: "گ",        # ;+Alt
    # Row 3
    52: "ۚ",   # Z+Alt
    53: "ۨ",   # X+Alt
    54: "ڈ",        # C+Alt → do chashmi dal
    55: "ڑ",        # V+Alt → do chashmi reh
    56: "ژ",        # B+Alt → zhe
    57: "ؓ",   # N+Alt
    58: "ٖ",   # M+Alt
    61: "÷",        # /+Alt
    20: "_",        # -+Alt → underscore
    # Selected digits
    11: "ؐ",   # 2+Alt
    15: "ٱ",   # 6+Alt → alef wasla
    16: "۞",        # 7+Alt
    17: "ٕ",   # 8+Alt
    18: "ۂ",        # 9+Alt
}
