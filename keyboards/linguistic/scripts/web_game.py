#!/usr/bin/env python3
"""
web_game.py — Web frontend for the LSD verb pairing game.

Usage:
  python3 scripts/web_game.py
  Then open http://localhost:5050
"""

import json
import pathlib
from flask import Flask, jsonify, request, send_from_directory

ROOT       = pathlib.Path(__file__).parent.parent
VERBS_FILE = ROOT / "seed" / "urdu_verbs.json"
PAIRS_FILE = ROOT / "seed" / "lsd_verb_pairs.json"
STATIC     = pathlib.Path(__file__).parent

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Data helpers

def load_pairs() -> list[dict]:
    PAIRS_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not PAIRS_FILE.exists():
        return []
    return json.loads(PAIRS_FILE.read_text(encoding="utf-8"))

def save_pairs(pairs: list[dict]):
    PAIRS_FILE.write_text(
        json.dumps(pairs, ensure_ascii=False, indent=2), encoding="utf-8"
    )

def load_verbs() -> list[dict]:
    return json.loads(VERBS_FILE.read_text(encoding="utf-8"))

def build_queue(verbs, pairs):
    done = {(p["urdu_infinitive"], p["urdu_label"]) for p in pairs}
    queue = []
    for verb in verbs:
        for form in verb["forms"]:
            if (verb["infinitive"], form["label"]) not in done:
                queue.append({
                    "infinitive": verb["infinitive"],
                    "meaning":    verb["meaning"],
                    "label":      form["label"],
                    "urdu_word":  form["word"],
                    "urdu_roman": form["roman"],
                })
    return queue

# ---------------------------------------------------------------------------
# API

@app.get("/api/next")
def api_next():
    verbs  = load_verbs()
    pairs  = load_pairs()
    queue  = build_queue(verbs, pairs)
    total  = sum(len(v["forms"]) for v in verbs)
    done   = total - len(queue)
    if not queue:
        return jsonify({"done": True, "total": total, "completed": done})
    return jsonify({"done": False, "total": total, "completed": done, "prompt": queue[0]})

@app.post("/api/submit")
def api_submit():
    data  = request.json
    pairs = load_pairs()
    pairs.append({
        "urdu_infinitive": data["infinitive"],
        "urdu_meaning":    data["meaning"],
        "urdu_label":      data["label"],
        "urdu_word":       data["urdu_word"],
        "urdu_roman":      data["urdu_roman"],
        "lsd_word":        data["lsd_word"],
        "lsd_roman":       data["lsd_roman"],
    })
    save_pairs(pairs)
    return jsonify({"saved": len(pairs)})

@app.post("/api/skip")
def api_skip():
    data  = request.json
    pairs = load_pairs()
    pairs.append({
        "urdu_infinitive": data["infinitive"],
        "urdu_meaning":    data["meaning"],
        "urdu_label":      data["label"],
        "urdu_word":       data["urdu_word"],
        "urdu_roman":      data["urdu_roman"],
        "lsd_word":        None,
        "lsd_roman":       None,
        "skipped":         True,
    })
    save_pairs(pairs)
    return jsonify({"saved": len(pairs)})

@app.get("/api/stats")
def api_stats():
    pairs = load_pairs()
    answered = [p for p in pairs if not p.get("skipped")]
    return jsonify({"total_pairs": len(answered), "total_skipped": len(pairs) - len(answered)})

@app.get("/")
def index():
    return send_from_directory(STATIC, "web_game.html")

if __name__ == "__main__":
    print("━" * 50)
    print("  LSD Verb Game")
    print("  http://localhost:5050")
    print("  Ctrl-C to stop")
    print("━" * 50)
    app.run(port=5050, debug=False)
