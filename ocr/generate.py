#!/usr/bin/env python3
"""
Generate a synthetic OCR training set for Lisan ud-Dawat.

For every corpus line, every selected font, and every point size, we render a
clean line image plus N augmented variants, and write each as an image alongside
a ground-truth text file. Output is in tesstrain's expected layout
(``<stem>.png`` + ``<stem>.gt.txt`` per line), which feeds straight into
``make training`` to produce ``fatemi.traineddata`` for the website. A
``manifest.jsonl`` is also written so the same data can train a transformer
recogniser later.

Examples
--------
    # Default: FatemiMaqala + Kanz al-Marjaan, sample corpus, 4 variants/line
    python3 ocr/generate.py

    # Your own corpus, more variants, include AlFatemi for display lines
    python3 ocr/generate.py --corpus mytext.txt --variants 6 \
        --fonts fatemimaqala kanzalmarjaan alfatemi

See TRAINING.md for what to do with the output.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib

import numpy as np

import fonts as font_registry
from augment import augment
from corpus import load_lines
from normalize import strip_vocalization
from pdfsource import collect_pdfs, ingest_pdf, ingest_pdf_legacy
from render import render_line, pad_to_min_width

HERE = pathlib.Path(__file__).resolve().parent
DEFAULT_CORPUS = HERE / "data" / "corpus.txt"
DEFAULT_OUT = HERE / "data" / "ground-truth"


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description="Render Lisan ud-Dawat text into a labelled OCR dataset.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument("--corpus", type=pathlib.Path, default=DEFAULT_CORPUS,
                   help="UTF-8 text file of Lisan ud-Dawat lines.")
    p.add_argument("--out", type=pathlib.Path, default=DEFAULT_OUT,
                   help="Output directory for image + .gt.txt pairs.")
    p.add_argument("--fonts", nargs="*", default=None,
                   help=f"Font ids to render. Default: "
                        f"{' '.join(font_registry.DEFAULT_FONTS)}. "
                        f"Known: {' '.join(font_registry.FONTS)}.")
    p.add_argument("--variants", type=int, default=4,
                   help="Augmented variants per (line, font, size). The clean "
                        "render is always emitted in addition to these.")
    p.add_argument("--sizes", type=int, nargs="*", default=None,
                   help="Override point sizes for all fonts.")
    p.add_argument("--max-words", type=int, default=12,
                   help="Split corpus lines into chunks of at most this many words.")
    p.add_argument("--unvocalized-frac", type=float, default=0.35,
                   help="Fraction of samples to render WITHOUT iʿrāb. Vocalization "
                        "is optional in Lisan ud-Dawat, so training on a mix of "
                        "voweled and plain text makes the model handle both. Only "
                        "applies to lines that actually carry marks.")
    p.add_argument("--eval-frac", type=float, default=0.05,
                   help="Fraction of corpus lines held out for evaluation.")
    p.add_argument("--limit", type=int, default=0,
                   help="If >0, use at most this many corpus lines (for quick tests).")
    p.add_argument("--seed", type=int, default=1424,
                   help="RNG seed for reproducible augmentation.")
    # PDF ingestion ---------------------------------------------------------
    p.add_argument("--pdf", type=pathlib.Path, nargs="*", default=None,
                   help="PDF files or directories to ingest. Pages with a usable "
                        "text layer become REAL (image, text) training pairs; "
                        "pages that are garbled or image-only are routed to "
                        "<out>/needs-ocr/ for OCR or manual transcription.")
    p.add_argument("--pdf-dpi", type=int, default=200,
                   help="Resolution to rasterise PDF pages at.")
    p.add_argument("--pdf-no-convert", action="store_true",
                   help="Skip double-press → Unicode conversion of extracted "
                        "text (use if the PDF text is already proper Unicode).")
    p.add_argument("--pdf-min-arabic", type=float, default=0.5,
                   help="A page's text layer must be at least this fraction "
                        "Arabic-script to be trusted; otherwise the page is "
                        "treated as image-only and sent to needs-ocr.")
    p.add_argument("--pdf-no-synth", action="store_true",
                   help="Don't also render PDF-extracted text synthetically in "
                        "the project fonts (by default we do, for extra variety).")
    p.add_argument("--pdf-legacy", action="store_true",
                   help="Decode PDFs set in a LEGACY LSD font (e.g. "
                        "AL-FATEMI/Lisaan-ud-Dawat) whose ToUnicode is scrambled, "
                        "by image-matching each glyph against FatemiMaqala "
                        "(legacy_decode). ~90%% accurate — check --pdf-verify.")
    p.add_argument("--pdf-verify", type=int, default=12,
                   help="Save this many extracted (crop, label) pairs as a "
                        "<out>/verify.png contact sheet for visual QA. Extraction "
                        "order for RTL text is producer-dependent — check this "
                        "before trusting a batch. 0 disables.")
    return p.parse_args()


def split_of(line: str, eval_frac: float) -> str:
    """Deterministically assign a line to train/eval by hashing its text, so a
    given line always lands in the same split across runs."""
    if eval_frac <= 0:
        return "train"
    h = int(hashlib.sha1(line.encode("utf-8")).hexdigest()[:8], 16) / 0xFFFFFFFF
    return "eval" if h < eval_frac else "train"


def main() -> None:
    args = parse_args()

    specs = font_registry.resolve(args.fonts)

    rng = np.random.default_rng(args.seed)
    train_dir = args.out / "train"
    eval_dir = args.out / "eval"
    train_dir.mkdir(parents=True, exist_ok=True)
    eval_dir.mkdir(parents=True, exist_ok=True)

    manifest = (args.out / "manifest.jsonl").open("w", encoding="utf-8")
    counts = {"train": 0, "eval": 0}

    # PDFs first: they yield REAL pairs written directly, and their extracted
    # text is fed into the synthetic corpus below (unless --pdf-no-synth).
    pdf_lines: list[str] = []
    if args.pdf:
        pdf_lines = ingest_pdfs(args, manifest, train_dir, eval_dir, counts)

    # Synthetic corpus = text file (if present) + text recovered from PDFs.
    lines: list[str] = []
    if args.corpus.is_file():
        lines = load_lines(args.corpus, max_words=args.max_words)
        if args.limit > 0:
            lines = lines[: args.limit]
    elif not args.pdf:
        raise SystemExit(f"Corpus not found: {args.corpus} (and no --pdf given)")
    if pdf_lines and not args.pdf_no_synth:
        lines = lines + pdf_lines

    if not lines and counts["train"] + counts["eval"] == 0:
        raise SystemExit("Nothing to generate: empty corpus and no PDF text.")

    print(f"Synthetic corpus lines: {len(lines)}  |  fonts: "
          f"{', '.join(s.name for s in specs)}  |  variants: {args.variants}")

    for li, line in enumerate(lines):
        split = split_of(line, args.eval_frac)
        out_dir = eval_dir if split == "eval" else train_dir

        # Plain (unvocalized) spelling of this line. Only differs if the line
        # actually carries iʿrāb — otherwise there's nothing to strip.
        plain = strip_vocalization(line)
        has_marks = plain != line

        for spec in specs:
            sizes = args.sizes if args.sizes else spec.point_sizes
            for px in sizes:
                voc_base = render_line(line, str(spec.path), px,
                                       language=spec.language)
                plain_base = None  # rendered lazily, only if needed

                # variant 0 is the clean render; 1..N are augmented.
                for v in range(args.variants + 1):
                    drop_marks = (has_marks
                                  and rng.random() < args.unvocalized_frac)
                    if drop_marks:
                        if plain_base is None:
                            plain_base = render_line(plain, str(spec.path), px,
                                                     language=spec.language)
                        base, label = plain_base, plain
                    else:
                        base, label = voc_base, line

                    img = base if v == 0 else augment(base, rng)
                    # Guarantee enough CTC timesteps for the label, so dense
                    # voweled lines aren't silently dropped by the trainer.
                    img = pad_to_min_width(img, len(label))
                    stem = f"{spec_id(spec)}_{px}_{li:06d}_{v:02d}"
                    png = out_dir / f"{stem}.png"
                    img.save(png)
                    (out_dir / f"{stem}.gt.txt").write_text(label, encoding="utf-8")
                    manifest.write(json.dumps({
                        "image": str(png.relative_to(args.out)),
                        "text": label,
                        "font": spec.name,
                        "px": px,
                        "split": split,
                        "augmented": v != 0,
                        "vocalized": not drop_marks,
                        "source": "synthetic",
                    }, ensure_ascii=False) + "\n")
                    counts[split] += 1

    manifest.close()
    print(f"Done. train={counts['train']} eval={counts['eval']} samples")
    print(f"Output: {args.out}")
    print("Next: see ocr/TRAINING.md to build fatemi.traineddata.")


def ingest_pdfs(args, manifest, train_dir, eval_dir, counts) -> list[str]:
    """Ingest every --pdf, writing real (image, label) line pairs straight into
    the dataset and saving text-less pages to <out>/needs-ocr/. Returns the
    recovered Unicode text lines so they can also be rendered synthetically."""
    pdfs = collect_pdfs(args.pdf)
    if not pdfs:
        print("No PDF files found under --pdf paths.")
        return []

    ocr_dir = args.out / "needs-ocr"
    text_lines: list[str] = []
    verify: list[tuple] = []  # (crop image, label) pairs for the QA sheet
    n_real = n_ocr = 0

    decoder = None
    if args.pdf_legacy:
        from legacy_decode import LegacyDecoder
        print("Legacy-font mode: building FatemiMaqala glyph templates...")
        decoder = LegacyDecoder()

    for pdf in pdfs:
        if args.pdf_legacy:
            res = ingest_pdf_legacy(
                pdf, decoder,
                dpi=args.pdf_dpi,
                min_arabic_frac=args.pdf_min_arabic,
            )
        else:
            res = ingest_pdf(
                pdf,
                dpi=args.pdf_dpi,
                convert=not args.pdf_no_convert,
                min_arabic_frac=args.pdf_min_arabic,
            )
        stem = pdf.stem.replace(" ", "_")

        for i, pl in enumerate(res.lines):
            split = split_of(pl.text, args.eval_frac)
            out_dir = eval_dir if split == "eval" else train_dir
            name = f"pdf_{stem}_{pl.page:03d}_{i:05d}"
            png = out_dir / f"{name}.png"
            pl.image.save(png)
            (out_dir / f"{name}.gt.txt").write_text(pl.text, encoding="utf-8")
            manifest.write(json.dumps({
                "image": str(png.relative_to(args.out)),
                "text": pl.text,
                "font": None,            # real PDF rendering, not one of our fonts
                "px": None,
                "split": split,
                "augmented": False,
                # A printed line carries whatever vocalization it was set with.
                "vocalized": strip_vocalization(pl.text) != pl.text,
                "source": "pdf",
                "pdf": pdf.name,
                "page": pl.page,
            }, ensure_ascii=False) + "\n")
            counts[split] += 1
            n_real += 1
            text_lines.append(pl.text)
            if len(verify) < args.pdf_verify:
                verify.append((pl.image, pl.text))

        if res.needs_ocr:
            ocr_dir.mkdir(parents=True, exist_ok=True)
            for pg in res.needs_ocr:
                pg.image.save(ocr_dir / f"{stem}_{pg.page:03d}.png")
                n_ocr += 1

        print(f"  {pdf.name}: {res.n_text_pages} text page(s) → "
              f"{len(res.lines)} line(s); {res.n_image_pages} image/garbled "
              f"page(s) → needs-ocr")

    if verify:
        sheet = args.out / "verify.png"
        _verify_sheet(verify, sheet)
        print(f"  QA: wrote {len(verify)} (crop, label) pairs to {sheet} — "
              f"check the label matches the image before trusting the batch.")

    print(f"PDF ingest: {n_real} real line pair(s); {n_ocr} page(s) need OCR"
          + (f" (saved to {ocr_dir})" if n_ocr else ""))
    return text_lines


def _verify_sheet(pairs: list[tuple], out_png: pathlib.Path) -> None:
    """Stack each PDF line crop above the same text re-rendered in FatemiMaqala.
    If extraction + conversion are right, the two rows read the same."""
    from PIL import Image, ImageDraw

    fm = str(font_registry.FONTS["fatemimaqala"].path)
    rows = []
    for crop, label in pairs:
        crop = crop.convert("L")
        try:
            rendered = render_line(label, fm, 40)
        except Exception:
            rendered = Image.new("L", (crop.width, 48), 255)
        rows.append((crop, rendered))

    pad, gap = 10, 6
    W = max(max(c.width, r.width) for c, r in rows) + 2 * pad
    H = sum(c.height + r.height + gap + 18 for c, r in rows) + pad
    sheet = Image.new("L", (W, H), 255)
    draw = ImageDraw.Draw(sheet)
    y = pad
    for crop, rendered in rows:
        sheet.paste(crop, (W - crop.width - pad, y)); y += crop.height + gap
        sheet.paste(rendered, (W - rendered.width - pad, y)); y += rendered.height
        draw.line([(pad, y + 8), (W - pad, y + 8)], fill=200); y += 18
    sheet.save(out_png)


def spec_id(spec: font_registry.FontSpec) -> str:
    """Filesystem-safe short id from a font name."""
    return spec.name.lower().replace(" ", "").replace("-", "")


if __name__ == "__main__":
    main()
