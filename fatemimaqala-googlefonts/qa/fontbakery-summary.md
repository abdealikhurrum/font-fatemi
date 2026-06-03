# Font Bakery (check-googlefonts) — progress

| stage | FAIL |
|---|---|
| Original FatemiMaqala-Regular.ttf | 19 |
| Clean source + rehabilitated features | 5 |
| + Latin gaps filled from Crimson | 4 |
| + dropped Latin smcp | 3 |
| + canonical filename | 2 |
| + trimmed Latin to GF Latin Core | 2* |
| + figures made non-kerning (tabular) | 1 |

\* the trim dropped the spurious GF Phonetics target; tabular then surfaced as
the figures-kern issue, now fixed.

## Remaining FAIL (1)

- `googlefonts/glyphsets/shape_languages` — under `GF_TransLatin_Arabic`, the only
  failing item is Dutch `íj́` (combining acute must attach to j/J). Needs Latin
  combining-mark attachment anchors.

## Scope decision applied
Latin was trimmed to exactly **GF Latin Core** (the mandatory GF minimum); the
inherited extended-Latin/IPA/Cyrillic codepoints were dropped from the cmap so
the font is Arabic-focused and no longer held to the full GF Phonetics glyphset.
Arabic coverage and shaping are unchanged.