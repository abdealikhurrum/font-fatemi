"""
Aggregator server for the LSD keyboard federation pipeline.

Receives weight delta files from contributors, stores them, and triggers
FedAvg once enough deltas have accumulated for a round.

Run:
    pip install -r requirements.txt
    uvicorn server:app --host 0.0.0.0 --port 8000

Environment variables:
    ROUNDS_THRESHOLD   Minimum contributors per round (default: 3)
    STORAGE_DIR        Where to store weights and models (default: ./data)
    SECRET_TOKEN       Optional bearer token to gate uploads
"""

import os
import json
import hashlib
import logging
from pathlib import Path
from datetime import datetime, timezone

from fastapi import FastAPI, Request, HTTPException, Header
from fastapi.responses import FileResponse, JSONResponse
import uvicorn

from fedavg import run_fedavg
from github_publisher import publish_model

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

ROUNDS_THRESHOLD = int(os.getenv("ROUNDS_THRESHOLD", "3"))
STORAGE_DIR      = Path(os.getenv("STORAGE_DIR", "./data"))
SECRET_TOKEN     = os.getenv("SECRET_TOKEN", "")      # empty = no auth

PENDING_DIR  = STORAGE_DIR / "pending"
ARCHIVE_DIR  = STORAGE_DIR / "archive"
MODELS_DIR   = STORAGE_DIR / "models"
MANIFEST_FILE = STORAGE_DIR / "manifest.json"

for d in (PENDING_DIR, ARCHIVE_DIR, MODELS_DIR):
    d.mkdir(parents=True, exist_ok=True)

logging.basicConfig(level=logging.INFO)
log = logging.getLogger("aggregator")

app = FastAPI(title="LSD Federation Aggregator")

# ---------------------------------------------------------------------------
# Auth helper
# ---------------------------------------------------------------------------

def check_auth(authorization: str | None):
    if not SECRET_TOKEN:
        return
    if authorization != f"Bearer {SECRET_TOKEN}":
        raise HTTPException(status_code=401, detail="Unauthorized")

# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.post("/weights")
async def receive_weights(
    request: Request,
    x_base_version: str = Header(default="base"),
    authorization: str | None = Header(default=None),
):
    """
    Accepts a binary weight delta file from a contributor.
    Header X-Base-Version tells us which model the delta was computed against.
    Triggers FedAvg automatically when ROUNDS_THRESHOLD deltas accumulate.
    """
    check_auth(authorization)

    body = await request.body()
    if not body:
        raise HTTPException(status_code=400, detail="Empty body")

    # Deduplicate by content hash so the same device can't flood a round
    content_hash = hashlib.sha256(body).hexdigest()[:16]
    out_path = PENDING_DIR / f"{content_hash}.delta"

    if out_path.exists():
        log.info("Duplicate delta %s — skipped", content_hash)
        return {"status": "duplicate"}

    out_path.write_bytes(body)
    log.info("Stored delta %s (base=%s, size=%d bytes)", content_hash, x_base_version, len(body))

    pending = list(PENDING_DIR.glob("*.delta"))
    log.info("%d / %d deltas for next round", len(pending), ROUNDS_THRESHOLD)

    if len(pending) >= ROUNDS_THRESHOLD:
        _trigger_round(pending, base_version=x_base_version)

    return {"status": "accepted", "pending": len(pending), "threshold": ROUNDS_THRESHOLD}


@app.get("/model/latest")
async def get_latest_model():
    """Returns JSON describing the current merged model."""
    manifest = _load_manifest()
    if not manifest:
        raise HTTPException(status_code=404, detail="No model available yet")
    return JSONResponse(manifest)


@app.get("/model/download/{version}")
async def download_model(version: str):
    """Serves the merged model binary for a given version string."""
    path = MODELS_DIR / f"{version}.onnx"
    if not path.exists():
        raise HTTPException(status_code=404, detail="Version not found")
    return FileResponse(path, media_type="application/octet-stream", filename=f"lsd_model_{version}.onnx")


@app.post("/corpus")
async def receive_corpus_pairs(
    request: Request,
    authorization: str | None = Header(default=None),
):
    """
    Accepts approved word pairs from a contributor's device.
    Pairs are appended to a JSONL corpus file, one JSON object per line.
    The file is suitable for direct use as training data or publishing as a dataset.
    """
    check_auth(authorization)

    try:
        payload = await request.json()
        pairs   = payload.get("pairs", [])
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    if not pairs:
        raise HTTPException(status_code=400, detail="No pairs provided")

    # Validate structure — each entry must have lsd and roman strings
    for p in pairs:
        if not isinstance(p.get("lsd"), str) or not isinstance(p.get("roman"), str):
            raise HTTPException(status_code=400, detail="Each pair needs 'lsd' and 'roman' strings")

    corpus_file = STORAGE_DIR / "corpus.jsonl"
    with corpus_file.open("a", encoding="utf-8") as f:
        for p in pairs:
            f.write(json.dumps({"lsd": p["lsd"], "roman": p["roman"]}, ensure_ascii=False) + "\n")

    log.info("Corpus: received %d pairs (total lines: %d)", len(pairs), _corpus_line_count())
    return {"status": "accepted", "pairs_received": len(pairs)}


def _corpus_line_count() -> int:
    corpus_file = STORAGE_DIR / "corpus.jsonl"
    if not corpus_file.exists():
        return 0
    with corpus_file.open() as f:
        return sum(1 for _ in f)


@app.get("/status")
async def status():
    manifest = _load_manifest()
    pending  = len(list(PENDING_DIR.glob("*.delta")))
    return {
        "current_version": manifest.get("version") if manifest else None,
        "pending_deltas": pending,
        "threshold": ROUNDS_THRESHOLD,
    }

# ---------------------------------------------------------------------------
# FedAvg trigger
# ---------------------------------------------------------------------------

def _trigger_round(delta_files: list[Path], base_version: str):
    timestamp  = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S")
    new_version = f"v{timestamp}"
    out_model   = MODELS_DIR / f"{new_version}.onnx"

    log.info("Starting FedAvg round → %s", new_version)
    try:
        run_fedavg(
            delta_paths=[str(p) for p in delta_files],
            base_model_path=str(_current_model_path()),
            output_path=str(out_model),
        )
    except Exception as e:
        log.error("FedAvg failed: %s", e)
        return

    # Archive processed deltas
    for f in delta_files:
        f.rename(ARCHIVE_DIR / f"{new_version}_{f.name}")

    # Update manifest
    manifest = {
        "version":      new_version,
        "url":          f"/model/download/{new_version}",
        "created":      timestamp,
        "contributors": len(delta_files),
    }
    MANIFEST_FILE.write_text(json.dumps(manifest, indent=2))
    log.info("Round complete. New model: %s", new_version)

    # Publish to GitHub — triggers model-release.yml which creates a Release
    publish_model(version=new_version, contributors=len(delta_files))


def _current_model_path() -> Path:
    manifest = _load_manifest()
    if manifest:
        ver  = manifest["version"]
        path = MODELS_DIR / f"{ver}.onnx"
        if path.exists():
            return path
    # Fall back to the bundled base model
    return Path("base_model.onnx")


def _load_manifest() -> dict | None:
    if not MANIFEST_FILE.exists():
        return None
    return json.loads(MANIFEST_FILE.read_text())

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
