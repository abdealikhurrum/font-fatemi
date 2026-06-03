# Font Bakery (check-googlefonts) — before vs after

- **Original FatemiMaqala-Regular.ttf:** 19 FAIL
- **Stage-1 structural build:** 3 FAIL

## Cleared (16)
- family/win_ascent_and_descent
- googlefonts/family_name_compliance
- googlefonts/font_copyright
- googlefonts/name/line_breaks
- googlefonts/name/version_format
- googlefonts/repo/zip_files
- linegaps
- nested_components
- opentype/font_version
- opentype/glyf_non_transformed_duplicate_components
- opentype/layout_valid_script_tags
- smallcaps_before_ligatures
- smart_dropout
- tabular_kerning
- transformed_components
- whitespace_widths

## Remaining (3) — all genuine glyph/feature work
- case_mapping
- googlefonts/glyph_coverage
- googlefonts/glyphsets/shape_languages

## Method

1. FontForge: convert quadratic→cubic, removeOverlap, correctDirection, round, export UFO.
2. Add missing glyphs referenced by features (NULL, uniFEDB.long, f-ligatures).
3. Set GF metadata (family/version/copyright/designer/vendor/license) in UFO.
4. gftools builder (decompose, remove-overlaps, autohint, fix).
5. Post-process: unify vertical metrics (win=typo=hhea, lineGap 0, USE_TYPO_METRICS), nbsp=space, strip name newlines.

Built with features disabled (see ../REHAB.md); shaping features pending rehabilitation.