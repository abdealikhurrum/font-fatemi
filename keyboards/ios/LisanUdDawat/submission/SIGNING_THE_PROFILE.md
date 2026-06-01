# Signing the FatemiMaqala font profile

The app installs the FatemiMaqala font via a configuration profile
(`.mobileconfig`). An **unsigned** profile shows "Unsigned" in red on the install
screen; a **signed** one shows "Verified" in green with your org name and is
tamper-checked by iOS.

You cannot sign on the device (signing needs your private key, which must never
ship in the app), so the profile is made **static** and signed on your Mac, then
bundled. `ViewController.saveProfile()` automatically ships the bundled signed
profile if present, and falls back to generating an unsigned one otherwise — so
the app keeps working before you add the signed file.

## One-time setup

```bash
cd keyboards/ios/LisanUdDawat/submission

# 1. Build the static (unsigned) profile from the TTF
python3 build-profile.py            # -> FatemiMaqala.mobileconfig

# 2. Sign it (use a cert iOS trusts — your Apple Developer cert chains to a
#    trusted Apple root, so it shows "Verified"). Find the name with:
#       security find-identity -v
SIGN_CERT="Apple Development: Your Name (K52KL4RVGR)" ./sign-profile.sh
#    -> FatemiMaqala-signed.mobileconfig

# 3. Bundle the signed profile in the app (the synchronized group picks it up):
cp FatemiMaqala-signed.mobileconfig ../LisanUdDawat/FatemiMaqala.mobileconfig
```

Rebuild. "Save Profile" now shares the signed profile → "Verified" on install.

## Certificate notes
- **Apple Developer cert** (Apple Development / Apple Distribution): chains to a
  trusted Apple root → green "Verified". Simplest, recommended.
- **Public CA S/MIME or code-signing cert** (DigiCert, etc.): also "Verified".
- **Self-signed cert**: installs but shows "Not Verified" unless that cert's root
  is already trusted on the device. Avoid for distribution.

## Re-signing
Re-run all three steps whenever `FatemiMaqala-Regular.ttf` changes. The signed
profile is binary CMS — keep it out of plain-text diffs; it's a build artifact.
