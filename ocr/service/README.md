# Rate-limited FreeType glyph-matcher service

The high-accuracy LSD legacy-font decoder (`ocr/legacy_decode.py`, ~90%+) needs
C libraries (FreeType, fontTools, PyMuPDF) that can't run in a browser or a
Cloudflare Worker — so it runs in a **container**, behind a **rate-limiting
Cloudflare Worker**. This is the optional "high-accuracy converter" the website
can call for legacy-font PDFs (the in-browser OCR handles everything else).

```
browser ──POST /decode (PDF)──▶ Worker (per-IP rate limit + size cap, CORS)
                                  └─▶ Container (app.py → legacy_decode) ──▶ {text}
```

## Files
- `app.py` — HTTP service (`POST /decode`, `GET /health`) wrapping `legacy_decode`.
- `Dockerfile` — slim image (~104 MB), self-contained build context.
- `vendor/` — copies of the decoder modules + both fonts (refresh with `./prepare.sh`).
- `worker/index.ts` — rate-limiting Worker + `Decoder` Container class.
- `wrangler.jsonc` — container + Durable Object + rate-limit config.

## Test locally (no Cloudflare needed)
```bash
./prepare.sh
docker build -t lsd-freetype ocr/service          # from repo root
docker run --rm -p 8090:8080 lsd-freetype
curl -X POST --data-binary @some-legacy.pdf http://localhost:8090/decode
```

## Deploy to Cloudflare
**Requires the Workers Paid plan** (~$5/mo) — Cloudflare Containers needs it.
```bash
cd ocr/service
./prepare.sh
npm install
npx wrangler deploy            # builds the image, pushes it, deploys Worker + container
```
Then copy the deployed Worker URL into the website: set `FREETYPE_ENDPOINT` in
`abdealikhurrum.github.io/ocr.html` and redeploy. The "high-accuracy decode"
button appears only when that URL is set.

## Limits (edit in `wrangler.jsonc` / `app.py`)
- **Rate:** 20 conversions / 60s per IP (`ratelimits.simple`).
- **Size:** 25 MB/PDF (`MAX_BYTES`).
- **Pages:** 60/PDF (`MAX_PAGES`).
- **Cost:** `standard-1` (0.5 vCPU / 4 GiB), `sleepAfter = 10m` → **scales to zero**
  (≈$0 idle; you pay only for active conversion seconds + the $5/mo Workers Paid base).

## Other hosts
The container is host-agnostic. To run it on Fly.io / Render / Cloud Run instead,
deploy the image there and point any rate-limiter (or a free Cloudflare Worker
that just forwards) at its URL — only `worker/index.ts`'s container call changes.
