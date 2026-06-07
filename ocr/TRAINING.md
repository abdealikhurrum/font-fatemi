# From synthetic data to a shipped model

This walks the dataset produced by `generate.py` all the way to the
`fatemi.traineddata.gz` that the website's in-browser OCR tool loads.

## 1. Generate the dataset

```bash
python3 ocr/generate.py --corpus your_lsd_corpus.txt --variants 5
# -> ocr/data/ground-truth/{train,eval}/  (*.png + *.gt.txt pairs)
```

Bigger and more representative is better: aim for a corpus in the thousands of
distinct lines before expecting usable accuracy. Start smaller to validate the
loop end to end.

## 2. Train with tesstrain (Tesseract 5, LSTM)

[tesstrain](https://github.com/tesseract-ocr/tesstrain) fine-tunes on
`<stem>.gt.txt` + image pairs — exactly our output format.

```bash
# one-time: tesseract 5 with training tools + the tesstrain makefile
sudo apt-get install tesseract-ocr libtesseract-dev
git clone https://github.com/tesseract-ocr/tesstrain
git clone https://github.com/tesseract-ocr/tessdata_best   # for the ara start model

cd tesstrain
make training \
  MODEL_NAME=fatemi \
  START_MODEL=ara \
  TESSDATA=../tessdata_best \
  GROUND_TRUTH_DIR=../ocr/data/ground-truth/train \
  MAX_ITERATIONS=10000
# -> data/fatemi.traineddata
```

Fine-tuning from `ara` (the start model) means the network already knows Arabic
letterforms; we're teaching it our fonts, the iʿrāb, and the extended LSD
letters. Watch the training CER; push iterations up if it's still falling.

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
