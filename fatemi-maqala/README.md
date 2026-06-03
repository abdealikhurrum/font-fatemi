# Fatemi Maqala

A Lisan ud Dawat Arabic Naskh typeface — an original retracing and extension of
the Bohra manuscript naskh hand, prepared for Google Fonts onboarding.

This project exists as a sibling to, not a competitor of, Kanz al-Marjaan: it
carries a distinct design treatment of the shared lineage, released under OFL by
its author. See `AUTHORS.txt` for provenance and acknowledgement.

## Status — Google Fonts readiness

Font Bakery `check-googlefonts`, original FatemiMaqala → this project:

| | FAIL | notes |
|---|---|---|
| Original FatemiMaqala-Regular.ttf | **19** | quadratic/raster outlines, nested+transformed components, bad metrics, bad naming, no hinting |
| Stage-1 structural build (this repo) | **3** | only "needs-drawing" items remain (below) |

**Cleared** (via cubic conversion + outline repair + the GF build pipeline +
metadata): nested/transformed/duplicate components, invalid script tags, smart
dropout (hinting), tabular kerning, smallcaps order, repo zip hygiene, vertical
metrics (win/typo/hhea unified, lineGap 0, USE_TYPO_METRICS), family-name
compliance (FatemiMaqala → "Fatemi Maqala"), copyright, version format, name
line-breaks, whitespace widths.

**Remaining FAILs — all genuine glyph work:**
- `googlefonts/glyph_coverage` — draw U+00AE ®, U+013E ľ, U+1E9E ẞ
- `case_mapping` — add counterparts U+0256 ɖ, U+04D8 Ә
- `googlefonts/glyphsets/shape_languages` — complete Latin/phonetics coverage

**Plus the one large task: feature-file rehabilitation** — see `REHAB.md`. The
font does not yet shape Arabic in this repo because the inherited feature code
does not compile under `feaLib`; the stage-1 artifact was built with features
disabled to validate everything else.

## Layout
- `sources/Fatemi-Maqala-Regular.ufo` — canonical source: cleaned **cubic**
  outlines (overlaps removed, directions corrected), GF metadata set, and the
  full `features.fea` (source of truth, pending rehab).
- `sources/features.full.fea` — standalone copy of the full feature code.
- `sources/config.yaml` — gftools builder config.
- `fonts/FatemiMaqala-stage1-structural.ttf` — structural baseline (no shaping
  features) used for the Font Bakery measurement above. **Not for release.**

## Build
```
pip install -r requirements.txt
cd sources && gftools builder config.yaml   # green once features are rehabilitated
```

## Provenance / licensing
Original retracing by the author, released under SIL OFL 1.1 (`OFL.txt`),
acknowledging the Aljamea-tus-Saifiyah / Dawoodi Bohra origin of the tradition.
This is a community-significant script; release decisions were taken with that
in mind.
