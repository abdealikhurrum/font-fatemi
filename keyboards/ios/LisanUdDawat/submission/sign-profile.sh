#!/usr/bin/env bash
#
# Sign the static FatemiMaqala.mobileconfig so iOS shows "Verified" on install.
#
#   1) python3 build-profile.py                # produce the unsigned profile
#   2) SIGN_CERT="Apple Development: You (TEAMID)" ./sign-profile.sh
#   3) copy the signed file into the app folder so it ships in the bundle:
#        cp FatemiMaqala-signed.mobileconfig ../LisanUdDawat/FatemiMaqala.mobileconfig
#      then rebuild. saveProfile() picks up the bundled signed profile automatically.
#
# Find your certificate's common name with:  security find-identity -v
#
set -euo pipefail
cd "$(dirname "$0")"

IN="${1:-FatemiMaqala.mobileconfig}"
OUT="${2:-FatemiMaqala-signed.mobileconfig}"

if [ -z "${SIGN_CERT:-}" ]; then
  echo "Set SIGN_CERT to your signing certificate's common name, e.g.:"
  echo '  SIGN_CERT="Apple Development: Jane Doe (K52KL4RVGR)" ./sign-profile.sh'
  echo
  echo "Available identities:"
  security find-identity -v
  exit 1
fi

if [ ! -f "$IN" ]; then
  echo "Missing $IN — run: python3 build-profile.py"
  exit 1
fi

# CMS/PKCS#7 detached-content signature in the form iOS expects.
security cms -S -N "$SIGN_CERT" -i "$IN" -o "$OUT"
echo "Signed -> $OUT"

# Sanity check the signature decodes.
security cms -D -i "$OUT" >/dev/null && echo "Signature verifies."
echo
echo "Next: cp \"$OUT\" ../LisanUdDawat/FatemiMaqala.mobileconfig  (then rebuild)"
