#!/usr/bin/env python3
"""
Generate the static (unsigned) FatemiMaqala.mobileconfig from the bundled TTF.
Mirrors ViewController.buildMobileconfig exactly. Re-run when the font changes,
then re-sign with sign-profile.sh.

    python3 build-profile.py
    -> submission/FatemiMaqala.mobileconfig   (unsigned; sign it next)
"""
import os
import plistlib

HERE = os.path.dirname(os.path.abspath(__file__))
TTF = os.path.join(HERE, "..", "LisanUdDawat", "FatemiMaqala-Regular.ttf")
OUT = os.path.join(HERE, "FatemiMaqala.mobileconfig")

with open(TTF, "rb") as f:
    font_data = f.read()

font_payload = {
    "Font": font_data,                       # plistlib emits <data> (base64)
    "PayloadDescription": "FatemiMaqala typeface for Lisan ud Dawat",
    "PayloadDisplayName": "FatemiMaqala",
    "PayloadIdentifier": "com.exordiumnetworks.LisanUdDawat.font.FatemiMaqala",
    "PayloadOrganization": "Lisan ud Dawat",
    "PayloadType": "com.apple.font",
    "PayloadUUID": "B2C3D4E5-F6A7-8901-BCDE-F01234567890",
    "PayloadVersion": 1,
}
profile = {
    "PayloadContent": [font_payload],
    "PayloadDescription": "Installs FatemiMaqala so it is available in all apps",
    "PayloadDisplayName": "FatemiMaqala Font",
    "PayloadIdentifier": "com.exordiumnetworks.LisanUdDawat.fontprofile",
    "PayloadOrganization": "Lisan ud Dawat",
    "PayloadRemovalDisallowed": False,
    "PayloadType": "Configuration",
    "PayloadUUID": "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
    "PayloadVersion": 1,
}

with open(OUT, "wb") as f:
    plistlib.dump(profile, f)
print("wrote", OUT, "(", len(font_data), "bytes of font )")
