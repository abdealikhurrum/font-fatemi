font-fatemi
===========
This is a fork of the original AlFatemi font project started many years ago to enable Lisan ud Dawat to be written digitally. Due to their long history, these fonts have grown to be synonymous with digitized Lisan ud Dawat, and they are commonly used by many speakers of Lisan ud Dawat.
FatemiMaqala is a modified version of ALFATEMILSD (and its variants), and AlFatemi[mn] is a variant of AlFatemi1424 (the first Unicode-standards based Lisan ud Dawat font. The aim of these modifications is to enable cross-platform use of these fonts through conformance with Unicode standards and using OpenType features.
Currently, FatemiMaqala is the more developed of the two. However, they are both ready for use in production environments.
Features:
-------
* Ligatures for honorific appendages, so that their width is preserved after superscript
* Reduced file size through re-edited outlines and extensive referencing
* Unicode compliance

Usage (For FatemiMaqala):
----
* Use with any keyboard layout
  - If using a standard Arabic keyboard (only Arabic), you can use the double-press ligatures by setting the text language to Persian (Farsi).
  - With keyboards containing characters for Urdu/Farsi, you can use them directly.

Keyboards:
----

* Maqala - Arabic:
  - This is based on the 100th Milad font keyboard, which was in turn based on the Arabic-102 standard keyboard.
  - There are four levels:
    1. Normal keypress (contains arabic characters)
    2. Shift (commonly used characters in Lisan ud Dawat, punctuation)
    3. RightAlt/Ctrl+Alt (less commonly used characters, some Urdu and Farsi characters)
    4. Shift+(RightAlt/Ctrl+Alt) (Arabic numerals)

* Maqala - Urdu:
  - This is basically the same keyboard, but the positions of
    * arabic heh and goal heh
    * arabic kaaf and urdu kaaf
    * teh marbuta and goal teh marbuta
    * arabic yaa and farsi yaa
    have been switched, so that Urdu fonts can be used more easily.

Installation
****
Install from "keyboards" > "unicode" > "aramaq" (for arabic) and "urdmaq" (for urdu)
Run setup.exe to install, run it again to uninstall
In the languages section, add Arabic and Urdu (optional: add Persian as well) , and select "Maqala - Arabic" for arabic and farsi, "Maqala - Urdu" for Urdu.
