# Font Bakery (check-googlefonts): 0 FAIL

## Vertical metrics (normalized)
- typo = hhea = **2500 / −1400**, lineGap 0, **USE_TYPO_METRICS** on → line-height **1.90 em**.
- win = **3622 / 1710** = the full ink bbox, so the extreme combining marks
  (`uni06EA` low Quranic stop; `NameMe.1455` high diacritic) never clip.
- Earlier the metrics were set to the full bbox (2.60 em line-height); retuned so
  line spacing reflects normal text while win still prevents clipping.

## WARNs remaining (15) — all intentional, inherent, or onboarding-time

| WARN | disposition |
|---|---|
| gdef_mark_chars / gdef_spacing_marks | **intentional** — width-preserved honorifics |
| arabic_high_hamza, outline_jaggy/semi_vertical, overlapping_path_segments, math_signs_width, caps note | inherent retraced-outline / Crimson-Latin traits |
| alt_caron, soft_dotted | cosmetic Latin |
| ligature_carets | cursor-in-ligature positions; low value |
| unreachable_glyphs | ~11 unencoded Latin kept for kern refs |
| article/images, metadata/unreachable_subsetting, vendor_id, shape_languages (auxiliary) | resolved at GF onboarding (METADATA.pb / article / vendor registration) |

## Fixed in this pass
- stylisticset_description: ss01 = 'Urdu ghunna', ss02 = 'Straight reh'.
- meta/script_lang_tags: added `meta` table (Arab, Latn).
- caps_vertically_centered: resolved by the metrics retune.