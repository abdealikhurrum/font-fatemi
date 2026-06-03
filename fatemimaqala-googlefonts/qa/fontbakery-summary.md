# Font Bakery (check-googlefonts) — before vs after

- **Original FatemiMaqala-Regular.ttf:** 19 FAIL
- **This build (cleaned source + rehabilitated features):** 5 FAIL

## Remaining FAILs

_Genuine glyph work (to be filled from Crimson — see below):_
- `googlefonts/glyph_coverage` — U+00AE ®, U+013E ľ, U+1E9E ẞ
- `case_mapping` — U+0256 ɖ, U+04D8 Ә
- `googlefonts/glyphsets/shape_languages` — Latin/phonetics coverage

_Minor Latin-feature niceties (low priority for an Arabic family):_
- `smallcaps_before_ligatures` — GSUB lookup ordering of smcp vs liga
- `tabular_kerning` — slash/zero kern via kern classes

## What was fixed

- Outlines: quadratic→cubic, overlaps removed, directions corrected.
- Components: nested/transformed/duplicate decomposed by the build.
- **Feature file rehabilitated** (see REHAB.md): 24 duplicate substitutions removed,
  39 empty-class kern pairs removed, and the 3 mark-attachment lookups
  (kharoSingle/kharoLiga/marktomark) split per mark-class into sub-lookups —
  verified pixel-identical shaping vs. the original.
- Metrics unified (win=typo=hhea, lineGap 0, USE_TYPO_METRICS); naming, version,
  copyright, whitespace, hinting all GF-compliant.