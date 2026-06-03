# Diacritic collision census — how to run on a big corpus and share results

The collision tools live here:
- `collision_check.py` — detector (one string at a time).
- `collision_census.py` — runs the detector over a CSV corpus (e.g. **APCD**) and
  writes a small JSON summary.

Because corpora like APCD are too large to upload, the workflow is: **run the
census locally, share only the small `collision_summary.json`.** That file
contains aggregate counts per glyph-pair plus a handful of short example words —
no bulk corpus text — so it's safe and tiny to send back here.

## Setup (once)
```
python3 -m pip install uharfbuzz freetype-py numpy pillow fonttools
```

## Run the census
```
cd fatemimaqala-googlefonts/qa
python3 collision_census.py /path/to/APCD.csv --column <text_column> \
        --same-marks --out collision_summary.json
```
- `--column` is the CSV header of the (vocalised) text column.
- `--same-marks` also flags shadda-stack (mark-on-mark) collisions.
- Useful knobs: `--limit N` (first N rows for a quick pass), `--margin U`
  (near-miss tightness, default 35 units), `--max-words N`.

Quick smoke test first:
```
python3 collision_census.py /path/to/APCD.csv --column verse --limit 2000
```

## What you get
`collision_summary.json` ranks the collisions, e.g.:
```json
{
  "unique_marked_words": 84210,
  "total_collisions": 1234,
  "by_glyph_pair": [
    {"mark": "uni064F", "neighbor": "uniFEDC", "count": 540,
     "examples": ["مُلْكَهُ", "..."]}
  ]
}
```
The `mark ↔ neighbor` glyph-pairs tell us exactly which adjacencies to fix and
how often each occurs — so fixes are prioritised by real-world frequency and
done **by class** (one contextual rule per pattern), not word-by-word.

## Then
Send `collision_summary.json` back and we turn the top glyph-pairs into targeted
contextual rules (mark adjustment, spacing, or — where a single letter's
extender is the culprit, like the medial kaaf — an outline reshape).

## Note on the detector
- A "collision" = a mark glyph whose ink overlaps (or comes within `--margin`
  units of) a glyph from a **different cluster** (a neighbouring letter), with
  `--same-marks` additionally catching mark-on-mark overlaps within one cluster.
- It does **not** flag a mark sitting over its own base's composed pieces
  (dots/hamza) — those are same-glyph and need visual review, not this tool.
