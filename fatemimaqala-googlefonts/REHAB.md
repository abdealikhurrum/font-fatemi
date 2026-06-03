# Feature-file rehabilitation — COMPLETE

The Arabic shaping, ligatures, honorifics and mark positioning live in
`sources/Fatemi-Maqala-Regular.ufo/features.fea`. As exported from the FontForge
`.sfd`, this code did **not** compile under `feaLib` (the compiler fontmake /
Google Fonts use). It has now been rehabilitated and **compiles clean**; the
built font shapes Arabic correctly — verified pixel-identical to the original
shipping font across joining, ligatures and full vocalization.

## What was wrong and how it was fixed

| Issue | count | fix | risk |
|---|---|---|---|
| Lowercase/blank script tags (`dflt`, blank `script ;`) | few | `dflt`→`DFLT` in script position; drop blank | none |
| Missing glyph references (NULL, uniFEDB.long, f-ligatures) | 7 | added to the UFO (NULL empty; uniFEDB.long = copy of uniFEDB; f-ligs = composites) | none |
| Duplicate substitutions ("Already defined …") | 24 | kept the first definition, removed the redundant one | none |
| Empty-class kern pairs | 39 | removed no-op `pos @A @B` rules referencing an empty class | none |
| **Mark-class overlap** (a mark in 2 mark classes in one lookup) | root cause | **split the 3 mark lookups per mark class** (see below) | verified safe |

### The mark-class split (the substantive fix)
`feaLib` forbids a mark glyph being in two mark classes **within one lookup**.
FontForge had crammed six mark classes into a single mark-to-base lookup
(`kharoSingle`, 513 lines), and similarly `kharoLiga` and `marktomark`. The marks
(fatḥa, kasra, shadda, …) legitimately belong to several same-direction classes
(`@aboveSingle`/`@aboveLiga`/`@abovemark`/`@finaAnchor`, etc.), so deleting was
not an option.

Fix: each of the three lookups was split into one sub-lookup **per mark class**,
the `markClass` definitions hoisted to file scope, and the `mark`/`mkmk` feature
references rewired to the sub-lookups:
- `kharoSingle` → 6 sub-lookups (subSingle, supSingle, zer, belowSingle, aboveSingle, finaAnchor)
- `kharoLiga` → 5 sub-lookups
- `marktomark` → 2 sub-lookups

Each sub-lookup references exactly one mark class, so there is no within-lookup
overlap, and because every base keeps its anchor for every mark group (now via
separate lookups that all run), **mark placement is unchanged** — confirmed by
rendering.

## Remaining (not feature-related)
- 3 glyph-coverage / case-mapping / shape-languages FAILs — to be filled from
  Crimson (the source of the Latin glyphs).
- 2 minor Latin-feature niceties: `smallcaps_before_ligatures` (GSUB lookup
  order) and `tabular_kerning` (slash/zero) — low priority for an Arabic family.

## Reproduce
The rehab is baked into `sources/.../features.fea`. To re-verify it compiles,
build a no-features TTF that contains the full glyph set, then:
```
python3 -c "from fontTools.ttLib import TTFont; from fontTools.feaLib.builder import addOpenTypeFeatures; addOpenTypeFeatures(TTFont('nofeatures.ttf'),'sources/Fatemi-Maqala-Regular.ufo/features.fea'); print('ok')"
```
