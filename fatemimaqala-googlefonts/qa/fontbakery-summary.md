# Font Bakery (check-googlefonts) — progress

| stage | FAIL |
|---|---|
| Original FatemiMaqala-Regular.ttf | 19 |
| Clean source + rehabilitated features | 5 |
| + Latin gaps filled from Crimson | 4 |
| + dropped Latin smcp (small-caps) | 3 |
| + source renamed (canonical filename) | 2 |

## Remaining FAILs

- `googlefonts/glyphsets/shape_languages` — the font inherited a *partial* slice
  of Crimson's extended Latin, so Font Bakery holds it to the full GF Phonetics
  glyphset and fails for ~14 African letters (Ɛ Ɔ Ɲ Ɗ …, not in Crimson) plus
  some Latin combining-mark attachment. **Resolution under consideration:** trim
  Latin to exactly GF Latin Core (the mandatory floor) so the font is checked
  only against Core — which uses precomposed accents already present.
- `tabular_kerning` — slash/zero kern via kern classes; resolves with the same
  Latin-Core trim (drops the extended-figure kerning).

Everything else passes: outlines, components, metrics, naming, hinting,
feature compilation + correct Arabic shaping, glyph coverage, case mapping,
canonical filename.