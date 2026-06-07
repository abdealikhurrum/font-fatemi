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
from render import render_line

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
    p.add_argument("--eval-frac", type=float, default=0.05,
                   help="Fraction of corpus lines held out for evaluation.")
    p.add_argument("--limit", type=int, default=0,
                   help="If >0, use at most this many corpus lines (for quick tests).")
    p.add_argument("--seed", type=int, default=1424,
                   help="RNG seed for reproducible augmentation.")
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

    if not args.corpus.is_file():
        raise SystemExit(f"Corpus not found: {args.corpus}")

    specs = font_registry.resolve(args.fonts)
    lines = load_lines(args.corpus, max_words=args.max_words)
    if args.limit > 0:
        lines = lines[: args.limit]
    if not lines:
        raise SystemExit("Corpus produced no usable lines after normalisation.")

    rng = np.random.default_rng(args.seed)
    train_dir = args.out / "train"
    eval_dir = args.out / "eval"
    train_dir.mkdir(parents=True, exist_ok=True)
    eval_dir.mkdir(parents=True, exist_ok=True)

    manifest = (args.out / "manifest.jsonl").open("w", encoding="utf-8")
    counts = {"train": 0, "eval": 0}

    print(f"Corpus lines: {len(lines)}  |  fonts: "
          f"{', '.join(s.name for s in specs)}  |  variants: {args.variants}")

    for li, line in enumerate(lines):
        split = split_of(line, args.eval_frac)
        out_dir = eval_dir if split == "eval" else train_dir

        for spec in specs:
            sizes = args.sizes if args.sizes else spec.point_sizes
            for px in sizes:
                base = render_line(line, str(spec.path), px,
                                   language=spec.language)
                # variant 0 is the clean render; 1..N are augmented.
                for v in range(args.variants + 1):
                    img = base if v == 0 else augment(base, rng)
                    stem = f"{spec_id(spec)}_{px}_{li:06d}_{v:02d}"
                    png = out_dir / f"{stem}.png"
                    img.save(png)
                    (out_dir / f"{stem}.gt.txt").write_text(line, encoding="utf-8")
                    manifest.write(json.dumps({
                        "image": str(png.relative_to(args.out)),
                        "text": line,
                        "font": spec.name,
                        "px": px,
                        "split": split,
                        "augmented": v != 0,
                    }, ensure_ascii=False) + "\n")
                    counts[split] += 1

    manifest.close()
    print(f"Done. train={counts['train']} eval={counts['eval']} samples")
    print(f"Output: {args.out}")
    print("Next: see ocr/TRAINING.md to build fatemi.traineddata.")


def spec_id(spec: font_registry.FontSpec) -> str:
    """Filesystem-safe short id from a font name."""
    return spec.name.lower().replace(" ", "").replace("-", "")


if __name__ == "__main__":
    main()
