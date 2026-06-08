#!/usr/bin/env python3
"""
Evaluate a trained Lisan ud-Dawat model on a held-out split.

Reports the two numbers TRAINING.md asks for, separately:
  * base-letter CER  — iʿrāb stripped from BOTH prediction and ground truth,
    i.e. "did it read the letters" (the must-have).
  * vocalization CER — full CER on voweled samples only, marks included,
    i.e. "did it also get the iʿrāb" (the nice-to-have tier).

Plus overall CER and a per-font breakdown. Uses the `vocalized` flag and
`split` field written into manifest.jsonl by generate.py, so it scores exactly
the held-out samples. Runs the actual tesseract binary, so it measures the
shipped model, not an internal training metric.

    python3 eval_cer.py --manifest data/ground-truth/real/manifest.jsonl \
        --model fatemi_real --tessdata /work/ocr/data/_train --sample 600
"""
from __future__ import annotations

import argparse
import json
import pathlib
import random
import subprocess

from normalize import strip_vocalization


def levenshtein(a: str, b: str) -> int:
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def ocr(image: pathlib.Path, model: str, tessdata: str, psm: int) -> str:
    out = subprocess.run(
        ["tesseract", str(image), "-", "-l", model,
         "--tessdata-dir", tessdata, "--psm", str(psm)],
        capture_output=True, text=True,
    )
    return " ".join(out.stdout.split())


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--manifest", required=True, type=pathlib.Path)
    ap.add_argument("--model", required=True)
    ap.add_argument("--tessdata", required=True)
    ap.add_argument("--psm", type=int, default=13)
    ap.add_argument("--sample", type=int, default=600,
                    help="Random eval samples to score (0 = all).")
    ap.add_argument("--seed", type=int, default=13)
    args = ap.parse_args()

    base = args.manifest.parent
    rows = [json.loads(l) for l in args.manifest.open(encoding="utf-8")]
    ev = [r for r in rows if r.get("split") == "eval"]
    if args.sample and len(ev) > args.sample:
        random.seed(args.seed)
        ev = random.sample(ev, args.sample)
    if not ev:
        raise SystemExit("No eval samples in manifest (regenerate with --eval-frac > 0).")

    # accumulators: (edit_distance_sum, ref_len_sum)
    acc = {k: [0, 0] for k in ("overall", "base", "voc")}
    per_font: dict[str, list[int]] = {}
    n = 0
    for r in ev:
        img = base / r["image"]
        if not img.exists():
            continue
        gt = r["text"]
        pred = ocr(img, args.model, args.tessdata, args.psm)
        n += 1

        d = levenshtein(gt, pred); acc["overall"][0] += d; acc["overall"][1] += len(gt)

        gtb, prb = strip_vocalization(gt), strip_vocalization(pred)
        db = levenshtein(gtb, prb); acc["base"][0] += db; acc["base"][1] += len(gtb)

        if r.get("vocalized"):
            dv = levenshtein(gt, pred); acc["voc"][0] += dv; acc["voc"][1] += len(gt)

        f = r.get("font") or "pdf"
        pf = per_font.setdefault(f, [0, 0])
        pf[0] += db; pf[1] += len(gtb)

    def cer(pair):
        return 100.0 * pair[0] / pair[1] if pair[1] else float("nan")

    print(f"\nEvaluated {n} held-out samples with model '{args.model}' (psm {args.psm})")
    print("=" * 56)
    print(f"  base-letter CER (iʿrāb stripped) : {cer(acc['base']):6.2f}%   <- must-have")
    print(f"  vocalization CER (voweled only)  : {cer(acc['voc']):6.2f}%   <- nice-to-have")
    print(f"  overall CER (raw, marks included): {cer(acc['overall']):6.2f}%")
    print("-" * 56)
    for f, pair in sorted(per_font.items()):
        print(f"  base-letter CER [{f:16s}]: {cer(pair):6.2f}%  (n_ref_chars={pair[1]})")


if __name__ == "__main__":
    main()
