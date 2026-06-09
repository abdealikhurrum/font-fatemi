# High-accuracy FreeType glyph-matcher as an HTTP service.
# Self-contained build context (run ./prepare.sh first to refresh ./vendor):
#   docker build -t lsd-freetype ocr/service
# Works the same locally and on Cloudflare Containers (context = this dir).
# Slim — no tesseract / training tools, just what legacy_decode needs.

FROM python:3.12-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        libfreetype6 \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
        "PyMuPDF>=1.24" \
        "freetype-py" \
        "fonttools>=4.0" \
        "numpy>=1.24" \
        "Pillow>=10.0"

WORKDIR /app
# Font files go in /app/assets (NOT /app/fonts) so they don't shadow fonts.py.
COPY vendor/legacy_decode.py vendor/normalize.py vendor/fonts.py app.py /app/
COPY vendor/assets/ /app/assets/

ENV FM_FONT=/app/assets/FatemiMaqala-Regular.ttf \
    KANZ_FONT=/app/assets/KanzAlMarjaan-Regular.ttf \
    PORT=8080
EXPOSE 8080
CMD ["python", "app.py"]
