#!/usr/bin/env python3
"""
Recover text from PDFs typeset in a *legacy* Lisan ud-Dawat font.

Some born-digital LSD PDFs are set in old fonts (e.g. "AL-FATEMI(Lisaan-ud-
Dawat)") whose embedded ToUnicode CMap is scrambled: the glyphs render
correctly but the extracted text maps to the *wrong* codepoints, and the
embedded subset drops the real glyph names — so neither plain extraction, NFKC
(see normalize.fold_presentation_forms) nor bidi reordering can fix it.

The shapes, however, are intact. We own a modern Unicode face (FatemiMaqala)
that is a re-traced version of the same letters, so we can recover the text by
**matching each embedded glyph's image to FatemiMaqala's glyphs** and reading
off the Unicode of the closest match. Outlines differ (re-traced), so we compare
rasterised, size-normalised bitmaps by cosine similarity rather than exact
outlines. FatemiMaqala glyphs are labelled with their Unicode via cmap, GSUB
ligatures (so the الله / لله ligatures decode whole) and positional-form names.

This gets ~90% of the characters right automatically — enough to bootstrap a
draft a human can finish, or to feed the OCR trainer once spot-checked against
the --pdf-verify sheet. Known residuals: a dropped ح in some hah-ligatures, and
Urdu heh (ہ U+06C1) vs Arabic heh (ه) — the latter is usually the correct LSD
spelling anyway.

Requires: freetype-py, fonttools, PyMuPDF, numpy, Pillow.
"""

from __future__ import annotations

import unicodedata
from dataclasses import dataclass

import numpy as np
import freetype
from fontTools.ttLib import TTFont
from fontTools.agl import toUnicode
from PIL import Image

from fonts import REPO_ROOT

# Rendering / matching resolution. 96px box at 192px render resolves the dots
# that distinguish beh/teh/theh/yeh; lower values confuse them.
_BOX = 96
_PX = 192


def _is_arabic(cp: int) -> bool:
    return (
        0x0600 <= cp <= 0x06FF
        or 0xFB50 <= cp <= 0xFDFF
        or 0xFE70 <= cp <= 0xFEFF
    )


def _norm_vec(face: "freetype.Face", gid: int) -> np.ndarray | None:
    """Rasterise glyph `gid`, size-normalise into a _BOX square, return an
    L2-normalised flat vector (so stroke-weight differences from the re-trace
    matter less than shape)."""
    face.set_pixel_sizes(0, _PX)
    try:
        face.load_glyph(gid, freetype.FT_LOAD_RENDER)
    except Exception:
        return None
    b = face.glyph.bitmap
    if b.width == 0 or b.rows == 0:
        return None
    arr = np.array(b.buffer, np.uint8).reshape(b.rows, b.pitch)[:, : b.width]
    im = Image.fromarray(arr)
    im.thumbnail((_BOX, _BOX), Image.LANCZOS)
    canvas = Image.new("L", (_BOX, _BOX), 0)
    canvas.paste(im, ((_BOX - im.width) // 2, (_BOX - im.height) // 2))
    v = np.asarray(canvas, np.float32).ravel()
    n = np.linalg.norm(v)
    return v / n if n else None


class LegacyDecoder:
    """Decodes legacy-font glyphs to Unicode by image-matching against a modern
    reference face (FatemiMaqala by default). Build once, reuse across PDFs."""

    def __init__(self, reference_font: str | None = None):
        self.ref_path = reference_font or str(
            REPO_ROOT / "fatemimaqala" / "FatemiMaqala-Regular.ttf"
        )
        self._build_reference()

    def _label(self, name: str) -> str | None:
        """Unicode string a FatemiMaqala glyph represents: ligature components
        (GSUB) joined, else the base letter (cmap / positional-form name)."""
        if name in self._ligmap:
            seq = "".join(self._base_char(c) or "" for c in self._ligmap[name])
        else:
            seq = self._base_char(name) or ""
        seq = "".join(c for c in unicodedata.normalize("NFKC", seq) if c != " ")
        if seq and all(_is_arabic(ord(c)) for c in seq):
            return seq
        return None

    def _base_char(self, name: str) -> str | None:
        cp = self._rev.get(name)
        if cp is None:
            stem = name.split(".")[0]
            cp = self._rev.get(stem)
            if cp is None:
                u = toUnicode(stem)
                cp = ord(u) if u and len(u) == 1 else None
        if cp is None:
            return None
        return "".join(c for c in unicodedata.normalize("NFKC", chr(cp)) if c != " ") or None

    def _build_reference(self) -> None:
        ft = TTFont(self.ref_path, lazy=True)
        self._rev = {}
        for cp, gn in ft.getBestCmap().items():
            self._rev.setdefault(gn, cp)
        # GSUB ligature reverse map: ligature glyph -> component glyph names
        self._ligmap = {}
        try:
            for lk in ft["GSUB"].table.LookupList.Lookup:
                for st in lk.SubTable:
                    ligs = getattr(st, "ligatures", None)
                    if not ligs:
                        continue
                    for first, arr in ligs.items():
                        for lg in arr:
                            self._ligmap[lg.LigGlyph] = [first] + list(lg.Component)
        except Exception:
            pass
        face = freetype.Face(self.ref_path)
        vecs, labels = [], []
        for gid, name in enumerate(ft.getGlyphOrder()):
            lab = self._label(name)
            if lab is None:
                continue
            v = _norm_vec(face, gid)
            if v is not None:
                vecs.append(v)
                labels.append(lab)
        self._T = np.stack(vecs)
        self._labels = labels

    def decode_glyph(self, face: "freetype.Face", gid: int, _cache: dict) -> str:
        key = (id(face), gid)
        if key in _cache:
            return _cache[key]
        v = _norm_vec(face, gid)
        r = self._labels[int((self._T @ v).argmax())] if v is not None else ""
        _cache[key] = r
        return r


@dataclass
class _Glyph:
    x: float
    y: float
    ch: str
    bbox: tuple


def decode_page_lines(decoder: LegacyDecoder, page, faces: dict, cache: dict,
                      default_face=None, y_tol: float = 4.0) -> list[tuple[str, tuple]]:
    """Decode one page into logical-order text lines. `faces` maps a span font
    name to a freetype.Face of that embedded subset; `default_face` is used for
    Arabic spans whose font name isn't matched. Returns (text, bbox) per line,
    bbox in PDF points."""
    glyphs: list[_Glyph] = []
    for sp in page.get_texttrace():
        fname = sp.get("font", "")
        face = faces.get(fname) or faces.get(fname.split("+")[-1]) or default_face
        for c in sp.get("chars") or []:
            ucs, gid, origin, bbox = c[0], c[1], c[2], c[3]
            if 0x0600 <= ucs <= 0x06FF and face is not None:
                ch = decoder.decode_glyph(face, gid, cache)
            elif 0 < ucs < 0x110000:
                ch = chr(ucs)
            else:
                ch = ""
            if ch:
                glyphs.append(_Glyph(origin[0], origin[1], ch, bbox))
    # group into lines by baseline y, order each line right-to-left
    glyphs.sort(key=lambda g: g.y)
    lines: list[list[_Glyph]] = []
    for g in glyphs:
        if lines and abs(g.y - lines[-1][0].y) <= y_tol:
            lines[-1].append(g)
        else:
            lines.append([g])
    out = []
    for ln in lines:
        ln.sort(key=lambda g: -g.x)  # RTL
        text = unicodedata.normalize("NFC", "".join(g.ch for g in ln)).strip()
        xs0 = min(g.bbox[0] for g in ln); ys0 = min(g.bbox[1] for g in ln)
        xs1 = max(g.bbox[2] for g in ln); ys1 = max(g.bbox[3] for g in ln)
        out.append((text, (xs0, ys0, xs1, ys1)))
    return out
