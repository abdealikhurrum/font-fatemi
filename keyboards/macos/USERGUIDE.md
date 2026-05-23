# Lisan ud Dawat — macOS Keyboard User Guide

The LSD Keyboard is an Input Method for macOS that lets you type Arabic and Urdu text on a standard QWERTY keyboard. It follows the LSD physical key layout (also used on Windows and iOS) and adds features not possible with a simple keylayout file: double-press ligatures, diacritic composition mode, and per-character Urdu/Arabic codepoint toggles.

---

## Installation

See [README.md](README.md) for build and install instructions. Once installed, select the keyboard from the Input Sources menu in the menu bar. Three input modes are available under the *Lisan ud Dawat* entry.

---

## Input Modes

Switch between modes using the system Input Sources menu (the keyboard icon in the menu bar) or the keyboard shortcut you configure in System Settings.

| Mode | Layout |
|------|--------|
| **LSD (Windows PC)** | Standard LSD layout matching the Windows and iOS keyboards |
| **LSD (Mac)** | Mac-adapted variant; Arabic semicolon and comma on the base layer |
| **CRULP Urdu** | CRULP phonetic layout for Urdu |

---

## Typing Basics

The keyboard follows the LSD layout. Arabic letters are arranged on their standard positions. A few keys on the base layer that differ from a Latin keyboard:

- **Number row** — Arabic-Indic digits (١٢٣٤٥٦٧٨٩٠) instead of Western digits  
- **`-` and `=`** — pass through as `-` and `=` on the base layer  
- **`\`** — pass through as `\`

---

## Double-Press (Ligature Input)

Press the **same key twice quickly** to insert the secondary character. The first press shows the primary character in an underline composition; the second press replaces it with the secondary.

If you pause (longer than the configured delay), the primary is committed and the second press starts a new character.

### LSD / Arabic-Standard secondaries

| Primary | → Secondary |
|---------|-------------|
| ض | → ٹ |
| ث | → پ |
| ه | → ھ |
| ح | → چ |
| ج | → چھے (three-character ligature) |
| س | → ے |
| ي / ی | → ئ |
| ا | → اٰ or آ *(configurable, see Settings)* |
| ك / ک | → گ |
| ط | → ں |
| ر | → ڑ |
| ة / ۃ | → ۃ |
| د | → ڈ |
| ظ | → ہ |

### CRULP Urdu secondaries

| Primary | → Secondary |
|---------|-------------|
| ع | → غ |
| ر | → ڑ |
| ت | → ٹ |
| ح | → خ |
| د | → ڈ |
| ه / ہ | → ھ |
| ز | → ذ |
| ش | → ض |
| ن | → ں |

### Double-press settings

Open the **Settings menu** (click *Lisan ud Dawat* in the menu bar) to adjust:

- **Double-press** — enable or disable the feature entirely  
- **Double-press delay** — Short (0.25 s) / Normal (0.35 s, default) / Long (0.50 s)

---

## Shift Layer (⇧)

The shift layer puts Arabic diacritics on the QWERTY row and extended Urdu letters on ASDF and ZXCV.

### QWERTY row (diacritics)

| Key | Character | Name |
|-----|-----------|------|
| ⇧Q | ◌َ U+064E | Fatha |
| ⇧W | ◌ً U+064B | Fathatan |
| ⇧E | ◌ُ U+064F | Damma |
| ⇧R | ◌ٌ U+064C | Dammatan |
| ⇧T | ڤ U+06A4 | Ve |
| ⇧Y | إ U+0625 | Alef with hamza below |
| ⇧U | ◌ٗ U+0657 | Inverted damma |
| ⇧I | ھ U+06BE | Do-chashmi he |
| ⇧O | ٹ U+0679 | Tteh |
| ⇧P | ہ U+06C1 | He goal |
| ⇧[ | چ U+0686 | Tcheh |
| ⇧] | ڈ U+0688 | Ddal |

### ASDF row

| Key | Character | Name |
|-----|-----------|------|
| ⇧A | ◌ِ U+0650 | Kasra |
| ⇧S | ◌ٍ U+064D | Kasratan |
| ⇧D | ے U+06D2 | Yeh barree |
| ⇧F | پ U+067E | Peh |
| ⇧H | أ U+0623 | Alef with hamza above |
| ⇧J | ـ U+0640 | Tatweel |
| ⇧K | ، U+060C | Arabic comma |
| ⇧L | ں U+06BA | Nun ghunna |
| ⇧; | گ U+06AF | Gaf |
| ⇧' | " | Straight double quote |
| ⇧\` | ◌ّ U+0651 | Shadda |

### ZXCV row

| Key | Character | Name |
|-----|-----------|------|
| ⇧Z | ◌ٰ U+0670 | Superscript alef (kharo zabar) |
| ⇧X | ◌ْ U+0652 | Sukun |
| ⇧C | ◌ٖ U+0656 | Subscript alef |
| ⇧V | ڑ U+0691 | Rreh |
| ⇧B | : | Colon |
| ⇧N | آ U+0622 | Alef madda |
| ⇧M | ۃ U+06C3 | Teh marbuta goal |
| ⇧, | ؓ U+0613 | Arabic sign raddah |
| ⇧. | . | Full stop |
| ⇧/ | ؟ U+061F | Arabic question mark |
| ⇧\ | \| | Vertical bar |

### Number row (shifted)

`! @ # $ ٪ ^ & * ( ) _ +`

*(⇧5 gives Arabic percent sign ٪ U+066A)*

---

## Option Layer (⌥)

The option layer provides punctuation, brackets, dashes, quotation marks, and BiDi control characters.

### Dashes — ⌥ + number row punctuation

| Key | Character |
|-----|-----------|
| ⌥ - | – en dash U+2013 |
| ⌥ = | — em dash U+2014 |

### BiDi controls — ⌥ + number keys 1–7

| Key | Character | Name |
|-----|-----------|------|
| ⌥1 | U+200E | LRM — left-to-right mark |
| ⌥2 | U+200F | RLM — right-to-left mark |
| ⌥3 | U+2066 | LRI — left-to-right isolate |
| ⌥4 | U+2067 | RLI — right-to-left isolate |
| ⌥5 | U+2069 | PDI — pop directional isolate |
| ⌥6 | U+200D | ZWJ — zero-width joiner |
| ⌥7 | U+200C | ZWNJ — zero-width non-joiner |

### Quotation marks — ⌥ + QWERTY row

| Key | Character |
|-----|-----------|
| ⌥Q | ' U+2018 left single quotation mark |
| ⌥W | ' U+2019 right single quotation mark |
| ⌥E | " U+201C left double quotation mark |
| ⌥R | " U+201D right double quotation mark |
| ⌥T | … U+2026 ellipsis |
| ⌥Y | • U+2022 bullet |
| ⌥U | ‹ U+2039 single guillemet ← |
| ⌥I | › U+203A single guillemet → |
| ⌥O | « U+00AB double guillemet ← |
| ⌥[ | ﴾ U+FD3E Arabic ornate left parenthesis |
| ⌥] | ﴿ U+FD3F Arabic ornate right parenthesis |

### Brackets — ⌥ + ASDF row

| Key | Character |
|-----|-----------|
| ⌥A | { left curly bracket |
| ⌥S | } right curly bracket |
| ⌥D | [ left square bracket |
| ⌥F | ] right square bracket |
| ⌥G | < left angle |
| ⌥H | > right angle |
| ⌥J | © U+00A9 copyright |
| ⌥K | ® U+00AE registered |
| ⌥; | ؛ U+061B Arabic semicolon |

### Symbols & Arabic punctuation — ⌥ + ZXCV row

| Key | Character |
|-----|-----------|
| ⌥Z | ― U+2015 horizontal bar |
| ⌥X | ° U+00B0 degree sign |
| ⌥C | ™ U+2122 trademark |
| ⌥V | ± U+00B1 plus-minus |
| ⌥B | × U+00D7 multiplication sign |
| ⌥N | ÷ U+00F7 division sign |
| ⌥M | · U+00B7 middle dot |
| ⌥, | ، U+060C Arabic comma |
| ⌥/ | ؟ U+061F Arabic question mark |
| ⌥\` | ـ U+0640 tatweel (kashida) |
| ⌥Space | U+00A0 non-breaking space |

### Subtending marks — ⌥L and ⌥P (digit-collection mode)

These two keys begin a **subtending mark composition**. The mark visually extends over a following sequence of Arabic-Indic digits.

1. Press **⌥L** (sanah — year sign U+0601) or **⌥P** (safha — page sign U+0603).
2. Type Arabic-Indic digits. The composed text appears as marked (underlined) text.
3. Press **Return** or **Space** to commit.  Press **Escape** to cancel.  **Backspace** erases the last digit.

*Example: ⌥L then ١٤٤٦ produces* ؁١٤٤٦ *(year 1446).*

---

## Shift + Option Layer (⇧⌥)

The shift+option layer provides additional Urdu letters not on the base layer, plus ZWNJ on Space.

| Key | Character |
|-----|-----------|
| ⇧⌥Space | U+200C ZWNJ |
| ⇧⌥S | ے U+06D2 yeh barree |
| ⇧⌥D | ی U+06CC farsi yeh |
| ⇧⌥F | پ U+067E peh |
| ⇧⌥C | ڈ U+0688 ddal |
| ⇧⌥V | ڑ U+0691 rreh |
| ⇧⌥B | ژ U+0698 jeh |
| ⇧⌥T | ڤ U+06A4 ve |
| ⇧⌥I | ﬦ U+06D5 ae |
| ⇧⌥[ | چ U+0686 tcheh |
| ⇧⌥J | ٹ U+0679 tteh |
| ⇧⌥K | ں U+06BA nun ghunna |
| ⇧⌥; | ک U+06A9 Urdu kaaf |

---

## Diacritic Mode (Caps Lock ⇪)

Enabling Caps Lock switches the keyboard into **diacritic composition mode**. A floating reference panel appears in the bottom-right corner of the screen showing all available keys.

All harakat are reachable from the **left hand alone**. The right hand covers small Quranic diacritics, document marks, and Quranic pause marks.

When in diacritic mode, hold **⌥** to switch the reference panel to the Option-layer view (BiDi controls, brackets, punctuation).

### Left hand — base harakat

| Key | Diacritic | Name |
|-----|-----------|------|
| Q | ◌َ U+064E | Fatha |
| W | ◌ً U+064B | Fathatan |
| E | ◌ُ U+064F | Damma |
| R | ◌ٌ U+064C | Dammatan |
| T | ◌ٔ U+0654 | Hamza above |
| A | ◌ِ U+0650 | Kasra |
| S | ◌ٍ U+064D | Kasratan |
| D | ◌ٓ U+0653 | Maddah above |
| F | ◌ٰ U+0670 | Superscript alef (kharo zabar) |
| G | ◌ٕ U+0655 | Hamza below |
| Z | ◌ّ U+0651 | Shadda (tashdeed) |
| X | ◌ْ U+0652 | Sukun |
| C | ◌ٗ U+0657 | Inverted damma |
| V | ـ U+0640 | Tatweel (kashida) |
| B | U+200D | Zero-width joiner |
| \` | ؔ U+0614 | Takhallus sign |

### Right hand — small Quranic diacritics

| Key | Diacritic | Name |
|-----|-----------|------|
| Y | ◌ؘ U+0618 | Arabic small fatha |
| U | ◌ؚ U+061A | Arabic small kasra |
| I | ◌ؙ U+0619 | Arabic small damma |
| O | ◌ؕ U+0615 | Arabic small high tah |
| P | ◌۴ U+06E4 | Arabic small high madda |
| [ | ◌۳ U+06E3 | Arabic small low seen |
| ] | ◌ۭ U+06ED | Arabic small low meem |
| H | ◌۷ U+06E7 | Arabic small high yeh |
| J | ◌ۥ U+06E5 | Arabic small waw |
| K | ◌ۦ U+06E6 | Arabic small yeh |
| L | ◌ؖ U+0616 | Arabic small high ligature alef-lam-yeh |
| ; | ؐ U+0610 | Arabic sign SAWS |
| ' | ؑ U+0611 | Arabic sign AS |

### Right hand — document marks

| Key | Character | Name |
|-----|-----------|------|
| N | ۝ U+06DD | End of ayah |
| M | ۞ U+06DE | Rub el hizb |
| , | sajda marker | Sajda |
| . | ؓ U+0613 | Sign raddah |
| / | Taa-Ayn marker | High sign |

### Number row — Quranic pause and decoration marks

| Key | Character | Unicode |
|-----|-----------|---------|
| 1 | ۖ | U+06D6 small high ligature ṣad-lam-alef-maksura |
| 2 | ۗ | U+06D7 small high ligature qaf-lam-alef-maksura |
| 3 | ۘ | U+06D8 small high meem initial form |
| 4 | ۙ | U+06D9 small high lam alef |
| 5 | ۚ | U+06DA small high jeem |
| 6 | ۛ | U+06DB small high three dots |
| 7 | ۜ | U+06DC small high seen |
| 8 | ۟ | U+06DF small high rounded zero |
| 9 | ۠ | U+06E0 small high upright rectangular zero |
| 0 | ۡ | U+06E1 small high dotless head of khah |
| - | ۢ | U+06E2 small high meem isolated |
| = | ۨ | U+06E8 small high noon |

---

## Settings Menu

Click **Lisan ud Dawat** in the Input Sources menu bar icon to open the settings.

### Double-press delay

Configures the timing window within which a second keypress is recognised as a double-press.

| Option | Delay |
|--------|-------|
| Short | 0.25 s |
| Normal | 0.35 s *(default)* |
| Long | 0.50 s |

### Double alef (اا)

Controls what typing alef twice produces:

| Option | Output |
|--------|--------|
| اٰ kharo zabar *(default)* | alef + superscript alef U+0627 U+0670 |
| آ alef madda | alef madda U+0622 |

### Character style toggles

Each toggle swaps an Arabic base codepoint for its Urdu/Farsi variant. The swap applies to **all layouts** and to all layers (normal, shift, option). Double-press secondaries are unaffected.

#### Yeh

| Option | Codepoint | Shape |
|--------|-----------|-------|
| Farsi/Urdu yeh *(default)* | U+06CC | ی |
| Arabic yeh | U+064A | ي |

#### Kaaf

| Option | Codepoint | Shape |
|--------|-----------|-------|
| Arabic kaaf *(default)* | U+0643 | ك |
| Urdu kaaf | U+06A9 | ک |

#### Haa

| Option | Codepoint | Shape |
|--------|-----------|-------|
| Arabic haa *(default)* | U+0647 | ه |
| Urdu he goal | U+06C1 | ہ |

#### Taa marbuta

| Option | Codepoint | Shape |
|--------|-----------|-------|
| Arabic taa marbuta *(default)* | U+0629 | ة |
| Urdu taa marbuta | U+06C3 | ۃ |

> **Note for mixed-script text:** Lisan ud Dawat text often requires both Arabic and Urdu codepoints in the same document. Toggle these settings as needed while typing. The system menu is accessible at any time without leaving your current app.

---

## Tips

**Typing brackets and punctuation in Arabic documents**  
Use the ⌥ layer. `⌥A` `⌥S` give `{ }`, `⌥D` `⌥F` give `[ ]`, `⌥G` `⌥H` give `< >`. Arabic punctuation is on `⌥,` (،), `⌥;` (؛), `⌥/` (؟).

**Smart quotes**  
`⌥Q` / `⌥W` give left/right single quotes ' ', `⌥E` / `⌥R` give left/right double quotes " ". Arabic ornate parentheses ﴾﴿ are on `⌥[` and `⌥]`.

**Diacritic entry workflow**  
Turn on Caps Lock. Use the left hand for all base harakat (Q–T for fathas/damma/dammatan/hamza, A–G for kasra/kasratan/maddah/kharo zabar/hamza below, Z–V for shadda/sukun/inv-damma/tatweel). The reference panel shows everything. Turn off Caps Lock to return to normal typing.

**Non-breaking space**  
`⌥Space` inserts a non-breaking space (U+00A0). `⇧⌥Space` inserts a zero-width non-joiner (U+200C).

**Keeping both Arabic and Urdu codepoints**  
If a font uses Arabic codepoints for some letters and Urdu for others, keep the character style toggles on their defaults and use `⇧⌥` layer characters (ے ی پ ڈ ڑ ژ ٹ ں ک) for the letters that must be Urdu codepoints, leaving the base layer in Arabic mode.

---

## Troubleshooting

**Keyboard doesn't appear after installation**  
See [README.md](README.md). Run `install.sh` and restart the TextInputMenuAgent, or log out and back in.

**Double-press is too fast / slow**  
Open Settings → Double-press delay and choose Short, Normal, or Long.

**Wrong codepoint for ي / ك / ه / ة**  
Open Settings and check the Yeh / Kaaf / Haa / Taa marbuta toggles. Switch between Arabic and Urdu forms as needed.

**Shift or Command shortcuts stop working in another app**  
This is fixed in recent versions. If it recurs, check Console.app filtered by `LSDKeyboard` for errors on `flagsChanged` events.
