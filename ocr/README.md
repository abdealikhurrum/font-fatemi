# Lisan ud-Dawat OCR — synthetic data generator

Off-the-shelf Arabic OCR struggles with Lisan ud-Dawat: it doesn't know the
extended Urdu/Persian letters and the doubled LSD forms, and it tends to drop or
mangle the iʿrāb (vowel marks). Vocalization is a *nice-to-have* in LSD — much
text is written unvocalized — so the priority is reading the base letters
correctly, with the marks captured faithfully when they're present. The fix is a
recogniser trained on LSD specifically, in both voweled and plain forms — and
the data for that is the usual blocker.

It isn't a blocker here, because **we own the fonts**. This package renders any
Unicode LSD text into perfectly-labelled line images in the exact typefaces real
pages use (FatemiMaqala, Kanz al-Marjaan), with realistic scan degradation. That
turns "we have no training data" into "we have unlimited training data."

The output feeds [tesstrain](https://github.com/tesseract-ocr/tesstrain) to
produce a `fatemi.traineddata` that drops straight into the in-browser OCR tool
on the website (the "Custom: FatemiMaqala" option in `ocr.html`).

## Layout

| File | Role |
|------|------|
| `fonts.py` | Registry of the typefaces to render, with point sizes. |
| `normalize.py` | Canonicalises ground-truth text — the one true spelling per word. |
| `corpus.py` | Loads a UTF-8 corpus into clean, line-level units. |
| `pdfsource.py` | Ingests PDFs: real (image, text) pairs from text pages, OCR queue for the rest. |
| `render.py` | Renders a line via Pillow + HarfBuzz (correct shaping & mark placement). |
| `augment.py` | Scan-like degradation: skew, blur, noise, ink spread, JPEG artifacts. |
| `generate.py` | CLI that ties it together and writes the dataset. |
| `data/corpus.txt` | Small starter corpus — replace with your own text. |
| `fonts/KanzAlMarjaan-Regular.ttf` | Bundled Kanz al-Marjaan face (see attribution below). |
| `TRAINING.md` | Turning the dataset into `fatemi.traineddata` and shipping it. |

## Setup

Pillow **must** be built with libraqm or Arabic shaping and diacritic
positioning come out wrong (`render.py` refuses to run without it).

```bash
# system shaping library
sudo apt-get install libraqm0        # Debian/Ubuntu
# brew install libraqm               # macOS

pip install -r ocr/requirements.txt
python3 -c "from PIL import features; print('raqm:', features.check('raqm'))"
```

## Use

```bash
# Default: FatemiMaqala + Kanz al-Marjaan, starter corpus, 4 variants/line
python3 ocr/generate.py

# Your own corpus, more augmentation, add AlFatemi for display lines
python3 ocr/generate.py --corpus path/to/lsd.txt --variants 6 \
    --fonts fatemimaqala kanzalmarjaan alfatemi

# Quick smoke test
python3 ocr/generate.py --limit 5 --variants 1 --out /tmp/ocrtest
```

By default about 35% of samples are rendered **unvocalized** (iʿrāb stripped
from both image and label) so the model reads plain text as well as voweled
text — tune with `--unvocalized-frac` (0 = always voweled, 1 = always plain).

Output goes to `ocr/data/ground-truth/{train,eval}/` as `<stem>.png` +
`<stem>.gt.txt` pairs (tesstrain format), plus a `manifest.jsonl` describing
every sample — including a `vocalized` flag, so you can score voweled and plain
samples separately (and it's handy if you later train a transformer recogniser).

## Training from PDFs

Born-digital PDFs are a shortcut to *real* training data — the actual page image
paired with correct text, which beats synthetic. Point `--pdf` at files or
folders:

```bash
python3 ocr/generate.py --pdf scans/ --corpus data/corpus.txt --variants 3
```

For each PDF page:

- **Has a usable text layer** (predominantly Arabic-script): each text line is
  cropped from the rasterised page and labelled with its text. The text is run
  through the repo's `double_press_convert.convert_text` first, because LSD PDFs
  usually store the double-press shorthand (e.g. a space + Arabic semicolon for
  چھے) rather than final Unicode. These real pairs are written straight into the
  dataset, and the recovered text is *also* rendered synthetically in the
  project fonts (disable with `--pdf-no-synth`).
- **Garbled or image-only** (low Arabic-script fraction, or no text at all): no
  trustworthy label exists, so the page image is saved to `<out>/needs-ocr/` for
  OCR or manual transcription instead of being given a made-up label.

Useful flags: `--pdf-dpi` (raster resolution), `--pdf-no-convert` (text is
already proper Unicode), `--pdf-min-arabic` (text/garbled threshold),
`--pdf-verify N` (QA sheet).

### Three kinds of PDF text layer

LSD PDFs store text three ways; the generator recovers the first two:

1. **Proper Unicode / double-press** — handled by default (`double_press_convert`
   + `normalize`).
2. **Presentation forms** (shaped glyphs + ligatures like ﷲ, in logical order) —
   `normalize` folds these to letters automatically via NFKC.
3. **Legacy font** (e.g. *AL-FATEMI/Lisaan-ud-Dawat*) whose ToUnicode is
   scrambled and whose embedded subset drops glyph names — pass **`--pdf-legacy`**.
   It image-matches each glyph against FatemiMaqala (`legacy_decode.py`) and
   recovers ~90% of characters. Always check `--pdf-verify`: known residuals are
   the حم (hah-meem) ligature dropping its ح, and Urdu heh (ہ) vs Arabic heh (ه,
   often the correct LSD spelling). Needs `freetype-py`.

> **Check RTL extraction before a big run.** How a PDF stores reading order is
> producer-dependent, and getting it backwards silently corrupts every label.
> `--pdf-verify` writes `<out>/verify.png` — each line crop above the same text
> re-rendered in FatemiMaqala. If the two rows read the same, extraction and
> conversion are good; eyeball it before trusting a batch.

## The two things that decide quality

1. **Corpus** — the model can only read words it has seen. Feed it real LSD
   text covering the vocabulary, names, and honorifics you care about. The more
   representative the corpus, the better the recogniser.
2. **Ground-truth spelling** — every word must have one canonical Unicode
   spelling. `normalize.py` handles the mechanical part (NFC, stripping tatweel
   and invisibles); encode any deliberate house spelling rules in its
   `CANONICAL_MAP`. Inconsistent labels are the fastest way to wreck diacritic
   accuracy.

## Fonts & attribution

FatemiMaqala and AlFatemi are part of this repository. Kanz al-Marjaan
(`fonts/KanzAlMarjaan-Regular.ttf`) is © 2025 The Kanz Al Marjaan Project
Authors — see <https://github.com/HatimMasvi/Kanz-al-Marjaan>. It is bundled
here so the generator runs out of the box; refer to that project for its license
and the authoritative font files.
