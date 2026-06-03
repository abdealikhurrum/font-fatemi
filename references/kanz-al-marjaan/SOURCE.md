# Kanz al-Marjaan (reference copy)

`Kanz-al-Marjaan-Regular.ttf` here was **built from source**, not downloaded as a
binary, so it reflects the upstream outlines and the Google Fonts build pipeline.

- Upstream: https://github.com/HatimMasvi/Kanz-al-Marjaan
- Source format: UFO + designspace (`sources/Kanz-al-Marjaan.designspace`)
- Built commit: `588aaba569d6e5779adf8413f6ac2a61863fbc6a` (2025-06-14)
- Build command: `fontmake -m sources/Kanz-al-Marjaan.designspace -o ttf`
- Authors: Sh Moiz Badri (design), M Hatim Masvi / At-Talimiyah Office
- License: SIL Open Font License 1.1 (see `OFL.txt`)

Why it's here: Kanz al-Marjaan shares the Fatemi outline lineage but is the only
remix distributed with **clean vector source**. Its GF build runs
`DecomposeComponentsFilter` + `RemoveOverlapsFilter` and ships disciplined
metrics (UPM 2048, win = hhea, no PUA — honorifics via ligatures), making it the
useful "clean implementation" benchmark for this family.
