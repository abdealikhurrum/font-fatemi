#!/usr/bin/env python3
"""
collision_census.py — run the collision detector over a corpus (e.g. APCD) and
emit a SMALL, shareable summary (ranked glyph-pair collisions + example words).

The corpus stays on your machine; only the tiny JSON summary is meant to be
shared. No corpus text beyond a few short example tokens is written out.

Usage:
    python3 collision_census.py CORPUS.csv --column verse [options]

Options:
    --column NAME     CSV column holding the (vocalised) text          [required]
    --font PATH       font to test            [default: ../fonts/FatemiMaqala-Regular.ttf]
    --limit N         only scan the first N rows                       [default: all]
    --max-words N     cap words scanned (dedup)                        [default: 200000]
    --margin U        near-miss margin in font units                   [default: 35]
    --same-marks      also flag same-cluster mark-vs-mark (stack) collisions
    --examples K      example words to keep per glyph-pair             [default: 3]
    --out FILE        summary path                  [default: collision_summary.json]

Deps: same as collision_check.py (uharfbuzz, freetype-py, numpy, pillow, fonttools)
"""
import sys, os, csv, json, argparse, collections
sys.path.insert(0, os.path.dirname(__file__))
from collision_check import CollisionDetector, DEFAULT_FONT

# Arabic letters / marks range — used only to pick tokens worth testing
def has_mark(tok):
    return any(0x064B <= ord(c) <= 0x065F or ord(c) == 0x0670 for c in tok)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("corpus")
    ap.add_argument("--column", required=True)
    ap.add_argument("--font", default=DEFAULT_FONT)
    ap.add_argument("--limit", type=int, default=0)
    ap.add_argument("--max-words", type=int, default=200000)
    ap.add_argument("--margin", type=int, default=35)
    ap.add_argument("--same-marks", action="store_true")
    ap.add_argument("--examples", type=int, default=3)
    ap.add_argument("--out", default="collision_summary.json")
    a = ap.parse_args()

    det = CollisionDetector(a.font)
    csv.field_size_limit(10**7)
    pairs = collections.Counter()
    examples = collections.defaultdict(list)
    seen = set(); n_words = 0; n_rows = 0

    with open(a.corpus, newline="", encoding="utf-8") as f:
        rd = csv.DictReader(f)
        if a.column not in rd.fieldnames:
            sys.exit(f"column '{a.column}' not in CSV. columns: {rd.fieldnames}")
        for row in rd:
            n_rows += 1
            if a.limit and n_rows > a.limit:
                break
            text = (row.get(a.column) or "").strip()
            for tok in text.split():
                if not has_mark(tok) or tok in seen:
                    continue
                seen.add(tok); n_words += 1
                if n_words > a.max_words:
                    break
                for ma, ob, px in det.collisions(tok, margin_units=a.margin,
                                                  same_cluster_marks=a.same_marks):
                    key = f"{ma}|{ob}"
                    pairs[key] += 1
                    if len(examples[key]) < a.examples:
                        examples[key].append(tok)
            if n_words > a.max_words:
                break

    summary = {
        "font": os.path.basename(a.font),
        "rows_scanned": n_rows,
        "unique_marked_words": n_words,
        "margin_units": a.margin,
        "same_cluster_marks": a.same_marks,
        "total_collisions": sum(pairs.values()),
        "by_glyph_pair": [
            {"mark": k.split("|")[0], "neighbor": k.split("|")[1],
             "count": c, "examples": examples[k]}
            for k, c in pairs.most_common()
        ],
    }
    with open(a.out, "w", encoding="utf-8") as o:
        json.dump(summary, o, ensure_ascii=False, indent=2)
    print(f"scanned {n_words} unique marked words across {n_rows} rows")
    print(f"{summary['total_collisions']} collisions across {len(pairs)} glyph-pairs")
    print(f"-> {a.out}  (share THIS file; it contains no corpus beyond short examples)")
    for e in summary["by_glyph_pair"][:15]:
        print(f"   {e['count']:6}  {e['mark']} ↔ {e['neighbor']}   e.g. {' '.join(e['examples'])}")

if __name__ == "__main__":
    main()
