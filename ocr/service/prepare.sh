#!/usr/bin/env bash
# Refresh vendored decoder modules + fonts into ./vendor (run if ../legacy_decode.py
# or the fonts change). Keeps ocr/service a self-contained Docker build context.
set -e
cd "$(dirname "$0")"
cp ../legacy_decode.py ../normalize.py ../fonts.py vendor/
cp ../../fatemimaqala/FatemiMaqala-Regular.ttf vendor/assets/
cp ../fonts/KanzAlMarjaan-Regular.ttf vendor/assets/
echo "vendored: $(ls vendor vendor/assets)"
