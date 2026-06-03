# Feature-file rehabilitation — the remaining large task

The Arabic shaping, ligatures, honorifics and mark positioning all live in
`sources/features.fea` (also copied to `sources/features.full.fea`). This code
was exported from the FontForge `.sfd` and **does not compile under `feaLib`**
(the compiler fontmake/ufo2ft and Google Fonts use). Until it compiles, the
built font does not shape Arabic, so the stage-1 artifact ships with features
disabled.

`feaLib` is stricter than FontForge's old compiler. The errors fall into a few
categories (counts approximate — they cascade, so treat as magnitude):

| Category | ~count | What it is | Suggested remedy |
|---|---|---|---|
| Glyph in two classes in one rule | ~400+ | e.g. "Glyph uni064D cannot be in both @zer and @belowSingle"; "thinkharozabar in @supSingle and @…" | The same mark/glyph is listed in overlapping classes used by a single contextual/positioning rule. Restructure the rule or split the classes; do **not** just delete — it changes mark placement. |
| Empty glyph class in positioning | ~39 | a referenced class resolved to nothing | usually a downstream effect of the above; fixes when classes are corrected |
| Duplicate substitution | ~24 | "Already defined substitution for X, Y" (e.g. pehDouble.medi, ttehDouble.medi…) | genuine de-duplication: keep the first, remove the redundant rule |
| Lowercase/blank script tags | a few | `script dflt;`, blank `script ;`, `languagesystem dflt …` | `dflt`→`DFLT` in **script** position only (language `dflt` is correct); delete blank `script ;` |
| Missing glyph references | 7 (FIXED) | NULL, uniFEDB.long, f_f, f_i, f_f_i, f_l, f_f_l | already added to the UFO: NULL (empty), uniFEDB.long (copy of uniFEDB), f-ligatures (composites) |

## Recommended approach
1. Do **not** brute-force by commenting offending lines — that cascades into
   broken multi-line rules (`got SYMBOL <`) and silently changes shaping.
2. The class-overlap errors are the bulk. They come from contextual mark rules
   where a glyph legitimately belongs to multiple semantic classes but `feaLib`
   forbids overlap within a single rule's inputs. Resolve by refactoring those
   lookups (often: separate lookups per class, or per-glyph rules).
3. De-duplicate the ~24 duplicate substitutions.
4. Consider regenerating the joining/positional features cleanly rather than
   porting the tangled originals, since the positional forms are encoded as
   presentation-form glyphs (uniFE../uniFB..) mapped in init/medi/fina/isol.
5. Validate after every change with:
   `python3 -c "from fontTools.ttLib import TTFont; from fontTools.feaLib.builder import addOpenTypeFeatures; addOpenTypeFeatures(TTFont('test-target.ttf'),'features.fea')"`
   against a no-features build that contains the full glyph set.

This is careful, shaping-affecting work — it was deliberately left for review
rather than automated.
