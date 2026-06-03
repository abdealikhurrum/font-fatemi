#!/usr/bin/env python3
"""
collision_check.py — inter-character diacritic collision detector for Fatemi Maqala.

Shapes text with HarfBuzz, rasterises each glyph at its shaped position, and
reports where a MARK's ink overlaps (or comes within a near-miss margin of) a
glyph from a DIFFERENT cluster — i.e. a mark colliding with a neighbouring
letter. Optionally also flags same-cluster mark-vs-mark overlaps.

Usage:
    python3 collision_check.py [FONT.ttf] "vocalised text"
    python3 collision_check.py            # uses default font + a built-in sample

Deps: uharfbuzz, freetype-py, numpy, pillow, fonttools
"""
import sys, os
import uharfbuzz as hb, freetype, numpy as np
from PIL import Image, ImageFilter
from fontTools.ttLib import TTFont

DEFAULT_FONT = os.path.join(os.path.dirname(__file__), "..", "fonts", "FatemiMaqala-Regular.ttf")


class CollisionDetector:
    def __init__(self, font_path):
        self.path = font_path
        self.tt = TTFont(font_path)
        self.UPM = self.tt["head"].unitsPerEm
        self.order = self.tt.getGlyphOrder()
        n2g = {n: i for i, n in enumerate(self.order)}
        self.marks = set()
        gd = self.tt["GDEF"].table.GlyphClassDef if "GDEF" in self.tt else None
        if gd:
            self.marks = {n2g[g] for g, c in gd.classDefs.items() if c == 3}
        self.data = open(font_path, "rb").read()
        self.face = hb.Face(self.data)

    def collisions(self, text, px=600, margin_units=35, min_pixels=4,
                   same_cluster_marks=False):
        """Return list of (markGlyphName, otherGlyphName, overlap_px)."""
        fnt = hb.Font(self.face); fnt.scale = (self.UPM, self.UPM)
        buf = hb.Buffer(); buf.add_str(text); buf.guess_segment_properties()
        hb.shape(fnt, buf, {})
        ft = freetype.Face(self.path); ft.set_char_size(int(px * 64))
        sc = px / self.UPM
        k = max(1, int(round(margin_units * px / self.UPM)))
        glyphs = []; penx = 0.0; base_y = px * 2.0
        for i, p in zip(buf.glyph_infos, buf.glyph_positions):
            ft.load_glyph(i.codepoint, freetype.FT_LOAD_RENDER)
            b = ft.glyph.bitmap; w, h = b.width, b.rows
            x = penx + p.x_offset * sc + ft.glyph.bitmap_left
            y = base_y - p.y_offset * sc - ft.glyph.bitmap_top
            mask = (np.frombuffer(bytes(b.buffer), dtype=np.uint8).reshape(h, w) > 40
                    ) if (w and h) else np.zeros((0, 0), bool)
            glyphs.append(dict(gid=i.codepoint, cl=i.cluster, x=int(round(x)),
                               y=int(round(y)), w=w, h=h, mask=mask,
                               ismark=i.codepoint in self.marks))
            penx += p.x_advance * sc
        hits = []
        for m in glyphs:
            if not m["ismark"] or m["w"] == 0:
                continue
            gm = Image.fromarray((m["mask"] * 255).astype("uint8"))
            gm = gm.crop((-k, -k, m["w"] + k, m["h"] + k)).filter(ImageFilter.MaxFilter(2 * k + 1))
            gmask = np.array(gm) > 0; gx, gy = m["x"] - k, m["y"] - k; gh, gw = gmask.shape
            for o in glyphs:
                if o is m or o["w"] == 0:
                    continue
                same = o["cl"] == m["cl"]
                if same and not (same_cluster_marks and o["ismark"]):
                    continue
                if same and o["gid"] == m["gid"]:
                    continue
                ox0 = max(gx, o["x"]); oy0 = max(gy, o["y"])
                ox1 = min(gx + gw, o["x"] + o["w"]); oy1 = min(gy + gh, o["y"] + o["h"])
                if ox1 <= ox0 or oy1 <= oy0:
                    continue
                mm = gmask[oy0 - gy:oy1 - gy, ox0 - gx:ox1 - gx]
                oo = o["mask"][oy0 - o["y"]:oy1 - o["y"], ox0 - o["x"]:ox1 - o["x"]]
                inter = int(np.logical_and(mm, oo).sum())
                if inter >= min_pixels:
                    hits.append((self.order[m["gid"]], self.order[o["gid"]], inter))
        return hits


if __name__ == "__main__":
    args = list(sys.argv[1:])
    font = DEFAULT_FONT
    if args and args[0].lower().endswith((".ttf", ".otf")):
        font = args.pop(0)
    text = args[0] if args else "بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيْمِ مُلْكٌ كُلَّمَا"
    det = CollisionDetector(font)
    h = det.collisions(text, same_cluster_marks=True)
    if h:
        print(f"{len(h)} collision(s):")
        for a, b, n in h:
            print(f"  {a} ↔ {b}  ({n}px)")
    else:
        print("clean")
