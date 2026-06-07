# Lisan ud-Dawat OCR — synthetic data generator

Off-the-shelf Arabic OCR fails on Lisan ud-Dawat for two reasons: it ignores the
iʿrāb (vowel marks) that LSD depends on, and it doesn't know the extended
Urdu/Persian letters and the doubled LSD forms. The fix is a recogniser trained
on LSD specifically — and the data for that is the usual blocker.

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

Output goes to `ocr/data/ground-truth/{train,eval}/` as `<stem>.png` +
`<stem>.gt.txt` pairs (tesstrain format), plus a `manifest.jsonl` describing
every sample (handy if you later train a transformer recogniser instead).

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
