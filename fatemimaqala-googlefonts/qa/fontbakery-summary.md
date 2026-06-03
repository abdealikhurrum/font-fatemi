# Font Bakery (check-googlefonts) — progress

| stage | FAIL |
|---|---|
| Original FatemiMaqala-Regular.ttf | 19 |
| Clean source + rehabilitated features | 5 |
| + Latin gaps filled from Crimson | 4 |

## Remaining FAILs

- `canonical_filename` — build emits `Fatemi-Maqala-Regular.ttf`; the committed/
  release file is named `FatemiMaqala-Regular.ttf` (resolved on release).
- `googlefonts/glyphsets/shape_languages` — now Latin **mark attachment**
  (e.g. Dutch íj́: acutecomb not anchored to j/J), not missing glyphs. Needs
  Latin combining-mark anchors.
- `smallcaps_before_ligatures` — GSUB lookup order (smcp vs liga).
- `tabular_kerning` — slash/zero kern via kern classes.

All glyph-coverage and case-mapping FAILs are **resolved** by importing the
missing Latin glyphs (®, ľ, ẞ, ɖ, capital schwa, combining horn) from Crimson.

## Note — spurious small-caps family
The build also emits `Fatemi-MaqalaSC-Regular.ttf` because of the Latin
`smcp`/`c2sc` features (inherited with the Crimson Latin). For a Lisan ud Dawat
family these Latin small-caps are optional; dropping `smcp`/`c2sc` would remove
the SC artifact AND clear `smallcaps_before_ligatures`. Left as a decision.