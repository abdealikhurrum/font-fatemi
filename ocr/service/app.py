#!/usr/bin/env python3
"""
HTTP service wrapping the high-accuracy FreeType glyph-matcher (legacy_decode).

POST /decode  (body: a PDF)        -> {"text": "...", "pages": N, "decoded_pages": M}
GET  /health                       -> {"ok": true}

This is the server-side counterpart to the in-browser OCR: the FreeType matcher
needs C libraries (freetype, fontTools, PyMuPDF) that can't run in the browser
or in a Cloudflare Worker, so it lives in a container. A rate-limiting Cloudflare
Worker sits in front of it (see ocr/service/worker/). Host-agnostic — runs on
Cloudflare Containers, Fly, Render, Cloud Run, or a plain VM.

Env:
  FM_FONT / KANZ_FONT  paths to the reference fonts (defaults to bundled copies)
  MAX_BYTES            reject bodies larger than this (default 25 MB)
  MAX_PAGES            decode at most this many pages (default 60)
  PORT                 listen port (default 8080)
"""
from __future__ import annotations

import json
import os
import tempfile
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import fitz  # PyMuPDF
import freetype

from legacy_decode import LegacyDecoder, decode_page_lines

HERE = os.path.dirname(os.path.abspath(__file__))
FM = os.environ.get("FM_FONT", os.path.join(HERE, "fonts", "FatemiMaqala-Regular.ttf"))
KANZ = os.environ.get("KANZ_FONT", os.path.join(HERE, "fonts", "KanzAlMarjaan-Regular.ttf"))
MAX_BYTES = int(os.environ.get("MAX_BYTES", 25 * 1024 * 1024))
MAX_PAGES = int(os.environ.get("MAX_PAGES", 60))
PORT = int(os.environ.get("PORT", 8080))

LEGACY_MARKERS = ("FATEMI", "DAWAT", "LISAN", "LISAAN", "TAHERI")

# Build glyph templates once at startup (a few seconds), reuse for every request.
print("Building glyph templates (FatemiMaqala + Kanz)…", flush=True)
DECODER = LegacyDecoder(reference_fonts=[FM, KANZ])
print(f"Ready: {len(DECODER._labels)} templates", flush=True)


def decode_pdf(data: bytes) -> dict:
    with fitz.open(stream=data, filetype="pdf") as doc:
        n = min(doc.page_count, MAX_PAGES)
        out = []
        for pno in range(n):
            page = doc[pno]
            faces: dict = {}
            default = None
            tmps: list[str] = []
            for f in page.get_fonts(full=True):
                if f[1] != "ttf":
                    continue
                try:
                    tf = tempfile.NamedTemporaryFile(suffix=".ttf", delete=False)
                    tf.write(doc.extract_font(f[0])[-1])
                    tf.close()
                    tmps.append(tf.name)
                    face = freetype.Face(tf.name)
                    base = str(f[3])
                    faces[base] = face
                    faces[base.split("+")[-1]] = face
                    if any(m in base.upper() for m in LEGACY_MARKERS):
                        default = face
                except Exception:
                    pass
            if default is None and faces:
                default = next(iter(faces.values()))
            cache: dict = {}
            lines = decode_page_lines(DECODER, page, faces, cache, default)
            out.append("\n".join(t for t, _ in lines))
            for t in tmps:
                try:
                    os.unlink(t)
                except OSError:
                    pass
        return {"text": "\n\n".join(out).strip(), "pages": doc.page_count, "decoded_pages": n}


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, obj: dict) -> None:
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self._send(200, {"ok": True, "templates": len(DECODER._labels)})
        else:
            self._send(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/decode":
            self._send(404, {"error": "not found"})
            return
        length = int(self.headers.get("Content-Length", 0))
        if length <= 0:
            self._send(400, {"error": "empty body"})
            return
        if length > MAX_BYTES:
            self._send(413, {"error": f"PDF too large (max {MAX_BYTES} bytes)"})
            return
        data = self.rfile.read(length)
        try:
            self._send(200, decode_pdf(data))
        except Exception as e:  # malformed PDF, etc.
            self._send(400, {"error": f"could not decode: {e}"})

    def log_message(self, *args):  # quieter logs
        pass


if __name__ == "__main__":
    print(f"Listening on :{PORT}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
