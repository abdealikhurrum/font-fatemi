# Fatemi Maqala

A Lisan ud Dawat Arabic Naskh typeface — an original retracing and extension of
the Bohra manuscript naskh hand, prepared for Google Fonts onboarding.

This project exists as a sibling to, not a competitor of, Kanz al-Marjaan: it
carries a distinct design treatment of the shared lineage, released under OFL by
its author. See `AUTHORS.txt` for provenance and acknowledgement.

## Status — Google Fonts readiness

**Font Bakery `check-googlefonts`: 0 FAIL** (down from 19 on the original).

Cleared across the cleanup: cubic outline repair; full feature-file
rehabilitation (compiles + shapes Arabic identically to the original — see
`REHAB.md`); GF vertical metrics, naming, version, copyright, canonical filename,
hinting; Latin trimmed to exactly **GF Latin Core** (Arabic-focused — extended
Latin/IPA/Cyrillic dropped from the cmap); tabular (non-kerning) figures; and
generated Latin combining-mark attachment. See `qa/` for the stage-by-stage
table. Latin glyphs derive from Crimson and some Arabic from Amiri — both OFL,
acknowledged in `OFL.txt`.


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
