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
| Clean source + rehabilitated features | **5** | shaping-complete |
| + Latin gaps filled from Crimson | **4** | |
| + dropped Latin smcp (small-caps) | **3** | only the tail below remains |

**Cleared**: nested/transformed/duplicate components, invalid script tags, smart
dropout (hinting), repo zip hygiene, vertical metrics (win/typo/hhea unified,
lineGap 0, USE_TYPO_METRICS), family-name compliance, copyright, version format,
name line-breaks, whitespace widths; **the full feature-file rehabilitation**
(see `REHAB.md`) — the font now compiles and shapes Arabic, verified
pixel-identical to the original; and **glyph coverage + case mapping**, filled by
importing the missing Latin glyphs (®, ľ, ẞ, ɖ, capital schwa, combining horn)
from Crimson (acknowledged in `OFL.txt`).

**Remaining FAILs (the tail):**
- `canonical_filename` — release file named `FatemiMaqala-Regular.ttf` (resolved on release).
- `googlefonts/glyphsets/shape_languages` — Latin **mark attachment** (e.g. Dutch
  íj́), not missing glyphs; needs Latin combining-mark anchors.
- `tabular_kerning` — slash/zero kern via kern classes (minor).

The optional Latin `smcp` small-caps feature was dropped, which cleared
`smallcaps_before_ligatures` and removed a spurious small-caps build artifact.

## Layout
- `sources/Fatemi-Maqala-Regular.ufo` — canonical source: cleaned **cubic**
  outlines (overlaps removed, directions corrected), GF metadata, and the
  **rehabilitated** `features.fea`.
- `sources/features.full.fea` — standalone copy of the feature code.
- `sources/config.yaml` — gftools builder config.
- `fonts/FatemiMaqala-Regular.ttf` — shaping-complete build (vertical metrics
  post-patched). The committed binary is a convenience snapshot; the source is
  authoritative.
- `documentation/specimen.png` — rendered shaping sample.

## Build
```
pip install -r requirements.txt
cd sources && gftools builder config.yaml
```
The feature file compiles clean; the only post-step is the vertical-metrics
patch (until folded into the source/config).

## Provenance / licensing
Original retracing by the author, released under SIL OFL 1.1 (`OFL.txt`),
acknowledging the Aljamea-tus-Saifiyah / Dawoodi Bohra origin of the tradition.
This is a community-significant script; release decisions were taken with that
in mind.
