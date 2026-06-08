

# Reproducible Lisan ud-Dawat OCR training environment.
#
# Bundles everything the brief's Ubuntu recipe assumes, so the whole pipeline
# (data generation -> tesstrain LSTM fine-tune -> evaluate) runs identically on
# any host with Docker — in particular on Apple Silicon macOS, whose Homebrew
# tesseract ships the runtime but NOT the LSTM training tools.
#
# Provides:
#   - tesseract 5 + the training tools (lstmtraining, lstmeval,
#     combine_lang_model, unicharset_extractor, combine_tessdata, text2image)
#   - a libraqm-enabled Pillow (correct Arabic shaping + iʿrāb positioning),
#     numpy, PyMuPDF for the data generator
#   - the tesstrain harness at /opt/tesstrain
#   - the `ara` best/float start model at /opt/tessdata_best/ara.traineddata
#
# The repo worktree is bind-mounted at /work at run time (see run.sh), so source
# edits and generated data live on the host, not baked into the image.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# System packages: tesseract runtime + training tools, the shaping stack for
# raqm, build/util tooling, and python.
RUN apt-get update && apt-get install -y --no-install-recommends \
        tesseract-ocr \
        libtesseract-dev \
        libleptonica-dev \
        libpango1.0-dev \
        libcairo2-dev \
        libicu-dev \
        libraqm0 \
        libraqm-dev \
        libharfbuzz-dev \
        libfribidi-dev \
        libfreetype6-dev \
        python3 \
        python3-pip \
        python3-venv \
        git \
        make \
        wget \
        ca-certificates \
        bc \
        findutils \
    && rm -rf /var/lib/apt/lists/*

# Python deps for the generator. Modern Pillow wheels bundle raqm, but we install
# the system shaping libs above and verify raqm at build time so a broken image
# fails loudly here rather than silently rendering garbage later.
RUN pip3 install --no-cache-dir \
        "Pillow>=10.0" \
        "numpy>=1.24" \
        "PyMuPDF>=1.24" \
        "python-bidi" \
        "fonttools>=4.0" \
        "freetype-py" \
    && python3 -c "from PIL import features; assert features.check('raqm'), 'Pillow has no raqm — Arabic shaping would be wrong'; print('raqm OK')" \
    && python3 -c "import bidi.algorithm; print('python-bidi OK')"

# tesstrain harness (the Makefile that turns *.gt.txt + image pairs into a
# fine-tuned LSTM model).
RUN git clone --depth 1 https://github.com/tesseract-ocr/tesstrain.git /opt/tesstrain

# langdata: combine_lang_model needs radical-stroke.txt plus the per-script
# unicharsets (Arabic.unicharset, etc.) referenced by the merged unicharset.
# We fetch just these small files into /opt/langdata rather than cloning the
# multi-GB langdata_lstm repo, so `make training LANGDATA_DIR=/opt/langdata`
# finds them locally with no per-run network round-trips.
RUN mkdir -p /opt/langdata && cd /opt/langdata \
    && base=https://github.com/tesseract-ocr/langdata_lstm/raw/main \
    && wget -q "$base/radical-stroke.txt" \
    && for s in Arabic Armenian Bengali Bopomofo Canadian_Aboriginal Cherokee \
                Cyrillic Devanagari Ethiopic Georgian Greek Gujarati Gurmukhi \
                Hangul Han Hebrew Hiragana Kannada Katakana Khmer Lao Latin \
                Malayalam Myanmar Ogham Oriya Runic Sinhala Syriac Tamil \
                Telugu Thai Common; do \
         wget -q "$base/$s.unicharset" || echo "WARN: missing $s.unicharset"; \
       done \
    && test -s radical-stroke.txt && test -s Arabic.unicharset \
    && echo "langdata: $(ls *.unicharset | wc -l) script unicharsets + radical-stroke.txt"

# The `ara` best/float start model. We fetch only the single file rather than
# cloning all of tessdata_best (~1GB).
RUN mkdir -p /opt/tessdata_best \
    && wget -q -O /opt/tessdata_best/ara.traineddata \
        https://github.com/tesseract-ocr/tessdata_best/raw/main/ara.traineddata \
    && test -s /opt/tessdata_best/ara.traineddata

# Where tesseract looks for traineddata at inference time. We point it at the
# tesstrain output dir at run time via --tessdata-dir / TESSDATA_PREFIX.
ENV TESSDATA_PREFIX=/usr/share/tesseract-ocr/5/tessdata

WORKDIR /work
CMD ["/bin/bash"]
