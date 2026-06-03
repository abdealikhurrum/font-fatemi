# Font Bakery (check-googlefonts) — PASSING (0 FAIL)

| stage | FAIL |
|---|---|
| Original FatemiMaqala-Regular.ttf | 19 |
| Clean source + rehabilitated features | 5 |
| + Latin gaps filled from Crimson | 4 |
| + dropped Latin smcp | 3 |
| + canonical filename | 2 |
| + trimmed Latin to GF Latin Core | 2 |
| + figures made non-kerning (tabular) | 1 |
| + Latin combining-mark attachment | **0** |

## Summary of the cleanup

- **Outlines:** quadratic→cubic, overlaps removed, directions corrected.
- **Feature file rehabilitated** (REHAB.md): compiles under feaLib; Arabic shaping
  verified pixel-identical to the original.
- **Metrics/naming/hinting:** GF schema (win=typo=hhea, lineGap 0, USE_TYPO_METRICS),
  family 'Fatemi Maqala', version, copyright, canonical filename.
- **Latin scope:** trimmed to exactly GF Latin Core (Arabic-focused); extended/IPA/
  Cyrillic dropped from cmap. Latin from Crimson; some Arabic from Amiri (OFL.txt).
- **Figures:** made non-kerning (tabular).
- **Latin combining-mark attachment:** generated anchors so combining accents attach
  to Latin bases and the dotted circle (clears shape_languages + dotted_circle).

All `check-googlefonts` FAILs resolved. WARNs remain (e.g. some unreachable
unencoded glyphs retained for kerning) and can be pruned before submission.