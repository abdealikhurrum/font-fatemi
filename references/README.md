# References — Lisan ud Dawat font corpus

A research/comparison corpus for the font-fatemi project: the other remixes and
ancestors that share (or neighbour) the Fatemi outlines, kept under version
control so design and engineering decisions can be made against the actual
artifacts rather than from memory.

> **Licensing / provenance note.** These are third-party community fonts included
> here **for research and comparison**. Kanz al-Marjaan is SIL OFL 1.1 (license
> included). The `legacy/` fonts were distributed freely within the Dawoodi Bohra
> community (source: the Nottingham *emadrasah* distribution, `ldfonts.zip`); their
> formal licensing is unclear/undocumented. Do **not** redistribute or ship these
> outlines in a product without clarifying rights. They are here as evidence, not
> as a base to build on.

## Contents

### `kanz-al-marjaan/`
Built from OFL source — see `SOURCE.md`. The only remix with clean vector source;
the "what good looks like" benchmark for this family.

### `legacy/`
The classic Lisan ud Dawat set (from the Nottingham emadrasah `ldfonts.zip`).
The original archive also contained `Burhani Fonts 1 Prog.exe` (removed — an
unsigned executable that trips AV and blocks the archive) and `alfatemiver5.TTF`
(removed — corrupt: bad CRC, unsupported `post` table format).

Three distinct lineages live in this folder:

| File(s) | Family | Lineage | Notes |
|---|---|---|---|
| `AlFatemi14241.ttf` | Al-Fatemi LSD1424 ver 1 | **the Fatemi hand** | The AlFatemi1424 ancestor of FatemiMaqala. UPM 2152, 68% composite, bbox 2333/−1537 |
| `alfatemi152.TTF` | AL-FATEMI (Lisaan-ud-Dawat) | Fatemi hand | bbox top **3956** on a 2048 em → severe line-spacing/clipping |
| `Fatimi2.ttf`, `Fatimi5.ttf` | AlFatemi ARB v2.2 / LSD v5 | Fatemi hand | `Fatimi5` bbox top **3956** (same metric problem) |
| `Taheri.TTF`, `taheri.ttf` | Taheri | plainer naskh | a different, more upright design |
| `saifee.ttf`, `Burhani.ttf`, `Burhani1.ttf`, `badri.ttf` | Saifee / Burhani / Badri | plainer naskh | **same outlines re-badged** — identical bbox 2027/−1025, ~630/533 glyphs |
| `moahammadi.TTF`, `… Extended`, `… quraan`, `… thuluth` | Mohammadi family | separate naskh + thuluth | `thuluth` is a decorative display face |

Common defects across `legacy/` (the reasons these "break"): outlines that are
effectively traced rasters (no consistent extrema, overlaps, redundant points),
wild and inconsistent vertical metrics (bbox far exceeding the em), malformed
`name`/`post` tables, and inconsistent UPMs. These cannot be *optimized* into
robust print/screen fonts — only redrawn.

### `specimens/`
Rendered with HarfBuzz shaping + FreeType (see project tooling). Snapshots, not
canonical:

- `basmala-5way.png` — FatemiMaqala / AlFatemi vs Amiri / Scheherazade / Noto Naskh
- `kanz-vs-fatemi.png` — Kanz al-Marjaan vs FatemiMaqala vs AlFatemi (shared-outline check)
- `legacy-basmala.png` — the distinct legacy designs
- `screen-text-simulation.png` — simulated heavier/looser "screen text" cut vs Noto Naskh

## Benchmarks not committed
Amiri, Scheherazade New, Noto Naskh Arabic, Noto Nastaliq Urdu (all OFL) are used
in the specimens but are easily re-fetched from Google Fonts and are left out to
avoid bloat. Ask if you want them vendored too.
