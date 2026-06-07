# From synthetic data to a shipped model

This walks the dataset produced by `generate.py` all the way to the
`fatemi.traineddata.gz` that the website's in-browser OCR tool loads.

## 1. Generate the dataset

```bash
python3 ocr/generate.py --corpus your_lsd_corpus.txt --variants 5

# ...or fold in real pages from born-digital PDFs (best data you can get):
python3 ocr/generate.py --corpus your_lsd_corpus.txt --pdf scans/ --variants 5
# -> ocr/data/ground-truth/{train,eval}/  (*.png + *.gt.txt pairs)
# -> ocr/data/ground-truth/needs-ocr/      (text-less pages for transcription)
# -> ocr/data/ground-truth/verify.png      (QA: check RTL order is correct!)
```

Bigger and more representative is better: aim for a corpus in the thousands of
distinct lines before expecting usable accuracy. Start smaller to validate the
loop end to end. PDF pages with a real text layer give the highest-value samples
— see the README's "Training from PDFs" section, and always check `verify.png`
before a large run.

## 2. Train with tesstrain (Tesseract 5, LSTM)

[tesstrain](https://github.com/tesseract-ocr/tesstrain) fine-tunes on
`<stem>.gt.txt` + image pairs — exactly our output format.

### Toolchain

The training tools (`lstmtraining`, `lstmeval`, `combine_lang_model`, …) ship
with `tesseract-ocr` + `libtesseract-dev` on Debian/Ubuntu — but **not** with
Homebrew's tesseract on macOS. The repeatable way to get a correct environment
on any host (and the only sane way on Apple Silicon) is the bundled Docker image
`ocr/docker/Dockerfile`, which has tesseract 5 + training tools, a raqm-enabled
Pillow, PyMuPDF, **python-bidi** (required by the RTL recipe below), the
tesstrain harness at `/opt/tesstrain`, langdata at `/opt/langdata`, and the
`ara` start model at `/opt/tessdata_best`:

```bash
docker build -t lsd-ocr ocr/docker
# run anything with the repo bind-mounted at /work:
docker run --rm -v "$PWD":/work lsd-ocr bash -lc '...'
```

### The recipe that actually learns

> **Use `LANG_TYPE=RTL`.** This is the single most important flag and the reason
> an earlier fine-tune failed (BCER stuck ~99.8%, "Compute CTC targets failed",
> "null char mapped"). With the default blank `LANG_TYPE`, tesstrain builds the
> proto-model with an *empty* recoder and no `--lang_is_rtl`; fine-tuning an RTL
> script from `ara` on that mismatched recoder simply never learns. `LANG_TYPE=RTL`
> sets `--pass_through_recoder --lang_is_rtl` (and pulls in `generate_wordstr_box.py`,
> which needs `python-bidi`).

```bash
docker run --rm -v "$PWD":/work lsd-ocr bash -lc '
cd /opt/tesstrain && make -j"$(nproc)" training \
  MODEL_NAME=fatemi \
  START_MODEL=ara \
  LANG_TYPE=RTL \
  TESSDATA=/opt/tessdata_best \
  LANGDATA_DIR=/opt/langdata \
  DATA_DIR=/work/ocr/data/_train \
  GROUND_TRUTH_DIR=/work/ocr/data/ground-truth/train \
  MAX_ITERATIONS=10000'
# -> /work/ocr/data/_train/fatemi.traineddata
```

Fine-tuning from `ara` (the start model) means the network already knows Arabic
letterforms; we're teaching it our fonts, the iʿrāb, and the extended LSD
letters. Watch the training BCER; push iterations up if it's still falling.

> **Diacritic-dense lines and CTC timesteps.** Tesseract gives a line about
> `16 × width/height` CTC timesteps, and a line needs at least one per label.
> Tall iʿrāb stacks inflate height and starve the line of timesteps —
> "Compute CTC targets failed", and the sample is dropped. `generate.py` now
> pads such images horizontally (`render.pad_to_min_width`) so the densest
> voweled samples survive. If you still see CTC failures, lower `--max-words`
> or raise the `factor` in `pad_to_min_width`.

Sanity-check the loop before a long run: training one font of plain, short
Arabic lines from `ara` should drive BCER from ~100% into single digits within a
couple of thousand iterations. If it doesn't, the recipe — not the data — is
wrong.

> Tesseract's LSTM is the pragmatic first target because the result runs in the
> browser via Tesseract.js with no backend. If diacritic accuracy plateaus too
> low — likely for densely-voweled text — switch the recogniser to a
> transformer (TrOCR-style) trained on the same data via `manifest.jsonl`,
> exported to ONNX and run with `transformers.js`. The site is structured so
> only the model-loading path changes.

## 3. Evaluate on real pages

Synthetic CER is optimistic. Hold back a handful of **real** scans/photos with
hand-typed ground truth and measure CER/WER on those. Report two numbers:
base-letter accuracy (the thing that has to be right) and, separately,
vocalization accuracy on voweled samples. Vocalization is a nice-to-have in LSD,
so treat it as a bonus tier — don't let mark errors mask otherwise-correct
letter recognition. The `vocalized` flag in `manifest.jsonl` lets you split the
two cleanly.

```bash
tesseract real_page.png - -l fatemi --tessdata-dir tesstrain/data
```

## 4. Ship it to the website

Tesseract.js loads a gzipped traineddata named `<lang>.traineddata.gz` from the
configured `langPath`. The site's `ocr.html` looks in `assets/tessdata/` for the
`fatemi` model:

```bash
gzip -k tesstrain/data/fatemi.traineddata          # -> fatemi.traineddata.gz
mkdir -p /path/to/abdealikhurrum.github.io/assets/tessdata
cp tesstrain/data/fatemi.traineddata.gz /path/to/abdealikhurrum.github.io/assets/tessdata/
```

Commit that to the website repo, then pick **"Custom: FatemiMaqala"** in the
model dropdown on the OCR page. (The path is set by `CUSTOM_LANG_PATH` in
`ocr.html` — keep the two in sync if you move it.)

## 5. Close the loop

Every correction a user makes on the OCR page is real-world labelled data —
exactly the distribution synthetic data approximates. Capture those edits, fold
them into the corpus, and retrain. That feedback loop is what turns a decent
synthetic model into a genuinely good one.
