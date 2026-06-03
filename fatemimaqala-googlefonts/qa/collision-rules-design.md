# Kaaf-adjacency collision rules — design + status (WIP)

The medial/initial kaaf (`uniFEDC`/`uniFEDB`) has an arm that reaches up-and-right
over the **preceding** letter, colliding with that letter's above-mark. The agreed
design is a **three-group, context-sensitive** treatment of the preceding base,
verified with `qa/collision_check.py` (near-miss + same-cluster aware).

## The three groups (auto-detected by medial-form ink height; reviewed)

1. **Clear-top** — `ب ج ح س ص ع ي م ه`
   Drop the above-mark / shadda-cluster **down** so it nests under the kaaf arm.
   The cluster must move as a **unit** (shift the shadda; the vowel rides via mkmk
   — do *not* shift the vowel independently, or it double-shifts and crashes the
   shadda).

2. **Dotted (not tall)** — `ت ث خ ش ض غ ف ق ن`
   Insert a kashida (tatweel) before the kaaf — **only when an above-mark is
   present** (no mark ⇒ no collision ⇒ no widening).

3. **Long ascenders** — `ل ط ظ` (+ kaaf-before-kaaf)
   Insert a kashida **always**: *a little* if no mark, *more* if marked
   ("as good as joined").

Tatweel uses the existing kashida glyphs `uni0640.1` (≈270u, "little") /
`uni0640.3` (≈890u, "more"); insert via the `longlaamContext`→`longlaamkaafs`
convention (a context lookup calling a `sub kaf by tatweel kaf` lookup).

## What works (validated)
- **Long-ascender tatweel** (little vs. more) — fires and clears correctly.
- **GSUB chaining** generally (tatweel insertion, the existing `*Context` lookups).
- The **detector** objectively confirms clear/collide and ranks glyph-pairs.

## Blockers (open)
1. **Drop can't be restricted via contextual GPOS.** A bare
   `pos @vowels' <-Δ> [kaaf]` fires, but adding *any* backtrack
   (`pos @clearTop @vowels' <-Δ> [kaaf]`, even a single explicit glyph) makes it
   **not fire** in the `mark` feature. → Do the drop in **GSUB** instead: create
   lowered mark variants (`damma.low`, `fatha.low`, `shadda.low`, …) with anchors
   placed lower, and contextually substitute `normal → low` before the kaaf on
   clear-top bases (GSUB chaining works here). *Or* fall back to tatweel for
   clear-top too (simpler, slightly wider).
2. **Contextual glyph variants.** The font has ~133 `.lowtop`/`.hightop`/etc.
   positional variants (e.g. `uniFEE7.lowtop` for noon-init). The group classes
   must enumerate **all** variants of each base letter, or the rules miss real
   words. Build classes by scanning glyph names per base, not just simple frames.
3. **Tatweel width.** `uni0640.1` (270u) alone does **not** clear the arm; the
   "more" case needs `uni0640.3` (890u) or 2× `.1` (then `kashidas` collapses).
4. **Short alef-hamza.** `hamzaunderalefContext → shortalefs` does not fire
   (`وَإِذْ` keeps `uni0625`, no `.short`). Converting `sub X from [Y]` to
   `sub X by Y` did not help — the contextual application isn't reached; needs
   investigation (feature membership / ordering of that lookup).

## Recommended next steps
- Decide the drop mechanism (GSUB lowered-mark variants vs. tatweel-for-all).
- Enumerate all positional variants into the three classes.
- Tune tatweel widths to the "little/more" feel and re-check with the detector.
- Run `qa/collision_census.py` over APCD (see `SHARING.md`) to prioritise by
  real-world frequency.

This is iterative outline/feature work best finished in a font editor with the
detector as the objective check; the clean, validated font is unchanged in the
meantime.
