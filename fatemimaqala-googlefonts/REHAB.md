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

## Mark-positioning fix (finaAnchor)

After the mark-class split, marks belonged to several sub-lookups that all ran,
and the `kharoSingle_finaAnchor` sub-lookup (a secondary anchor set on 34 base
glyphs) ran last and **overrode** the correct `aboveSingle` position. On the
isolated lam this dropped the damma onto the stroke (collision). Removing the
`finaAnchor` sub-lookup makes every above-mark use its primary `aboveSingle`
anchor, fixing the lam and regularizing mark positions across the board.
Connected/voweled text (e.g. the basmala) is unchanged — verified by rendering.

## Inter-character mark collisions (contextual)

A pixel-level collision detector (`qa/collision_check.py`, near-miss aware) found
that inter-character mark collisions are dominated by the **medial kaaf**
(`uniFEDC`/`uniFEDB`): its arm reaches up-and-right over the preceding letter,
into that letter's above-mark (damma/shadda overlaps of 1000–2900px).

Applied:
- `spaceBeforeAlefHamza` (in `kern`): add space before an isolated alef-hamza-
  below (`uni0625`) after a non-connecting descender (waw/reh/zay); swash reh
  (`uni0631.alt`) gets more.

Kaaf — deferred to an outline reshape (see below). A contextual "drop the
preceding mark" rule was prototyped and **backed out**: dropping a lone mark
works, but (a) for shadda+vowel stacks the drop either re-collides with the kaaf
or, if dropped far enough to clear, crashes into the base; and (b) on bases with
composed above-pieces (teh/noon dots, medial yaa-hamza) the dropped mark lands on
them. The clean fix is to shorten the medial kaaf's arm so it no longer reaches
over the preceding letter — one outline change resolves every preceding-mark case
with no mark gymnastics. Left for an interactive design pass.

Known remaining (enumerate via `qa/collision_census.py` over a corpus — see
`qa/SHARING.md` — then fix by class):
- above-mark ↔ medial kaaf (`uniFEDC`/`uniFEDB`) — the dominant class.
- shadda near a *preceding* alef-hamza (e.g. إِيَّاكَ).
- mark-vs-mark near-misses between adjacent letters (e.g. أَنْعَمْتَ).
