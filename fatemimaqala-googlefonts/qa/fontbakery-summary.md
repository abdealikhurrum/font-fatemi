# Font Bakery (check-googlefonts) — progress

| stage | FAIL |
|---|---|
| Original FatemiMaqala-Regular.ttf | 19 |
| Clean source + rehabilitated features | 5 |
| + Latin gaps filled from Crimson | 4 |
| + dropped Latin smcp (small-caps) | 3 |

## Remaining FAILs

- `canonical_filename` — release file is `FatemiMaqala-Regular.ttf` (the builder
  emits a hyphen from the UFO name); resolved on release.
- `googlefonts/glyphsets/shape_languages` — Latin **mark attachment** (e.g. Dutch
  íj́: acutecomb not anchored to j/J), not missing glyphs. Needs Latin
  combining-mark anchors.
- `tabular_kerning` — slash/zero kern (-32, should be 0) via kern classes.

All glyph-coverage, case-mapping and feature-compilation issues are resolved;
the font builds from source and shapes Arabic identically to the original.
Dropping the optional Latin `smcp` feature cleared `smallcaps_before_ligatures`
and removed the spurious small-caps build artifact.