#!/usr/bin/env python3
"""
Post-pass for legacy-decoder output: raw glyph-matched text -> clean LSD text.

The glyph matcher (legacy_decode.py) is shape-only, so its raw output carries
systematic quirks of two kinds, both fixed here:

1. **Template confusions** — an embedded glyph whose closest reference template
   carries the wrong label. Verified against page images / a native reader on
   the 145-page m4-kifayat decode (AL-KANZ subsets, 2026-06):
     - zain matches the قى pair        -> رزق decodes رقىق, bold رزق ررقىقىقق
     - final heh-goal labels as ھ      -> يہ decodes يھ (the corpus writes
       aspiration with ه, so a decoded ھ is *always* a misread heh-goal)
     - the كہ heh-goal drops           -> the conjunction decodes as bare ك
     - the جہ ligature matches خ       -> the relative pronoun decodes as خ
       (neither bare ك nor bare خ is a word in LSD, so both folds are safe)
     - some subsets' reh matches ص     -> رسول decodes صسول (word list below)
     - some subsets' theh matches ٹ    -> مثل decodes مٹل (word list below)

2. **Source styling the decoder reads literally**:
     - double-press pairs typed in the legacy font (كك = گ, سس = ے, طط = ں)
     - emphasis doubling (bold by typing every letter twice: ققببوولل = قبول)
     - digits come out as mirrored ASCII runs (the decoder reads RTL and the
       reference labels digit glyphs with ASCII): "12" means ٢١

Styling is undone by lsd-normalize (the standalone normalizer at
~/Documents/lsd-normalize): its double-press conversion is marker-gated and its
doubling collapse requires a fully-doubled run, so genuine geminates (مؤسسة,
سبب) survive. Do NOT substitute the repo-root double_press_convert here — it
assumes fully-legacy input and corrupts the mostly-proper Unicode the decoder
emits (أئمة -> أة).

ORDER MATTERS: قى->ز must run *before* the doubling collapse (it turns bold
ررقىقىقق into the cleanly-doubled ررززقق), and heh-goal recovery *after* it
(so the collapse sees the decoder's literal output).

lsd-normalize is found via: installed package, $LSD_NORMALIZE_DIR,
/opt/lsd-normalize (mount it there when running in docker:
`-v ~/Documents/lsd-normalize:/opt/lsd-normalize`), or ~/Documents/lsd-normalize.
Without it, `require_normalizer=False` falls back to the doubling collapse only
(mirrored from lsd-normalize transforms.py) — double-press pairs then survive
unconverted.
"""
from __future__ import annotations

import os
import pathlib
import re
import sys
import unicodedata

# ---------------------------------------------------------------------------
# locating lsd-normalize
# ---------------------------------------------------------------------------
_NORMALIZE_DIRS = (
    os.environ.get("LSD_NORMALIZE_DIR", ""),
    "/opt/lsd-normalize",
    str(pathlib.Path.home() / "Documents" / "lsd-normalize"),
)


def _find_normalize_text():
    try:
        from lsd_normalize.pipeline import normalize_text  # installed
        return normalize_text
    except ImportError:
        pass
    for d in _NORMALIZE_DIRS:
        if d and (pathlib.Path(d) / "src" / "lsd_normalize").is_dir():
            sys.path.insert(0, str(pathlib.Path(d) / "src"))
            from lsd_normalize.pipeline import normalize_text
            return normalize_text
    return None


_AR_RUN = re.compile(r"[؀-ۿݐ-ݿࢠ-ࣿ]+")


def _collapse_emphasis_doubling(text: str) -> str:
    """Fallback mirror of lsd_normalize.transforms.collapse_emphasis_doubling:
    a fully pairwise-doubled Arabic run is always emphasis styling."""
    def fix(m):
        t = m.group(0); n = len(t)
        if n >= 4 and n % 2 == 0 and all(t[i] == t[i + 1] for i in range(0, n, 2)):
            return t[::2]
        return t
    return _AR_RUN.sub(fix, text)


# ---------------------------------------------------------------------------
# quirk tables
# ---------------------------------------------------------------------------
# Genuine words that legitimately end in قى and must survive the zain fix.
_ZAIN_PROTECT = ("يسقى",)

_EAST = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")

# standalone-word boundary within Arabic script
_B = r"(?<![؀-ۿ])%s(?![؀-ۿ])"

# Word-level fixes for the reh-as-sad and theh-as-tteh subset confusions.
# Every entry maps a non-word to the word a native reader confirmed on the
# page; genuine ص / ٹ words (صاحب, اونٹ, موٹو, مٹي...) are never touched.
WORD_FIXES = {
    "صسول": "رسول",     "وصس": "ورس",       "تاصے": "تارے",
    "اصے": "ارے",        "جيواصے": "جيوارے", "دوص": "دور",
    "ضروص": "ضرور",      "ضروصة": "ضرورة",   "اصشاد": "ارشاد",
    "مكرص": "مكرر",      "وصزقه": "ورزقه",   "تاروز": "تا روز",
    "مٹل": "مثل",        "كلٹوم": "كلثوم",   "الٹانية": "الثانية",
}


# ---------------------------------------------------------------------------
# pipeline
# ---------------------------------------------------------------------------
def fix_zain(text: str) -> str:
    """قى -> ز (run BEFORE the doubling collapse)."""
    for i, w in enumerate(_ZAIN_PROTECT):
        text = text.replace(w, "\x00%d\x00" % i)
    text = text.replace("قى", "ز")
    for i, w in enumerate(_ZAIN_PROTECT):
        text = text.replace("\x00%d\x00" % i, w)
    return text


def fix_quirks(text: str) -> str:
    """The stdlib-only fixes that run AFTER the doubling collapse."""
    # digits: mirrored ASCII runs -> reversed Arabic-Indic
    text = re.sub(r"\d+", lambda m: m.group(0)[::-1].translate(_EAST), text)
    # orthography fold to corpus standard
    text = text.replace("ک", "ك")
    # heh-goal recovery
    text = text.replace("ھ", "ہ")
    text = re.sub(_B % "ك", "كہ", text)
    text = re.sub(_B % "خ", "جہ", text)
    # subset-confusion word fixes
    for bad, good in WORD_FIXES.items():
        text = re.sub(_B % re.escape(bad), good, text)
    return text


def postprocess(text: str, *, require_normalizer: bool = True) -> str:
    """Full post-pass over decoder output (a line, a page, or a whole file)."""
    text = fix_zain(text)
    normalize_text = _find_normalize_text()
    if normalize_text is not None:
        text = normalize_text(text)
    elif require_normalizer:
        raise RuntimeError(
            "lsd-normalize not found — install it, set $LSD_NORMALIZE_DIR, or "
            "mount it in docker: -v ~/Documents/lsd-normalize:/opt/lsd-normalize "
            "(pass require_normalizer=False for the degraded stdlib fallback)"
        )
    else:
        text = _collapse_emphasis_doubling(text)
        text = unicodedata.normalize("NFC", text)
        text = "\n".join(" ".join(ln.split()) for ln in text.splitlines())
    return fix_quirks(text)
