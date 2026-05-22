# LSD Keyboard — Linux (IBus)

An [IBus](https://github.com/ibus/ibus) input method engine for **Lisan ud Dawat** (LSD), the Arabic-script language used by the Dawoodi Bohra community. Mirrors the iOS, Android, macOS, and Windows implementations in this repository.

## Features

- Full LSD character layout based on the Arabic physical keyboard (position-based X11 keycodes — works with any desktop keyboard layout)
- **Double-press rules** matching `lsd.kmn`: سس→ے · ضض→ٹ · طط→ں · ظظ→ہ · حح→چ · ثث→پ · كك→گ · and extensions
- **Alt layer** for extended characters: ے · ی · پ · ڈ · ڑ · ژ · ٹ · ں · گ · چ · ھ · ہ · ۃ
- Eastern Arabic-Indic digits on the number row
- Corpus logging to SQLite (`~/.local/share/lsd-keyboard/lsd_pairs.sqlite`) — same schema as iOS / macOS / Android

## Requirements

- Python 3.10+
- IBus daemon
- `python3-gi` / `gir1.2-ibus-1.0`

```bash
# Debian / Ubuntu
sudo apt install ibus python3-gi gir1.2-ibus-1.0

# Fedora / RHEL
sudo dnf install ibus python3-gobject
```

## Install

```bash
cd keyboards/linux
sudo ./setup.sh
```

Then: **IBus Preferences → Input Method → Add → search "Lisan ud Dawat"**.

## Development

```bash
# Run tests (no IBus required)
cd keyboards/linux
python -m pytest tests/ -v

# Run engine in foreground for live debugging
ibus-daemon -drx           # ensure daemon is running
python ibus-engine-lsd     # foreground mode; Ctrl-C to stop
```

## Layout reference

The mapping follows the LSD Mac keylayout. Key positions use the physical QWERTY letter labels for reference — the engine intercepts X11 hardware keycodes, so the layout is independent of the active desktop keyboard language.

### Normal layer

```
Q   W   E   R   T   Y   U   I   O   P   [   ]
ض   ص   ث   ق   ف   غ   ع   ه   خ   ح   ج   ة

A   S   D   F   G   H   J   K   L   ;   '
ش   س   ي   ب   ل   ا   ت   ن   م   ك   ؛

Z   X   C   V   B   N   M   ,
ظ   ط   ذ   د   ز   ر   و   ،
`  → ـ  (tatweel)
```

Digits 1–9 produce ١–٩ (Eastern Arabic-Indic); 0 → ٠.

### Double-press rules

| Press twice | Output |
|-------------|--------|
| س س | ے |
| ض ض | ٹ |
| ط ط | ں |
| ظ ظ | ہ |
| ح ح | چ |
| ث ث | پ |
| ك ك | گ |
| ا ا | اٰ |
| ه ه | ھ |
| ي ي | ئ |
| ر ر | ڑ |
| د د | ڈ |
| ة ة | ۃ |
| ج ج | چھے |

Default window: **500 ms** (configurable via `DOUBLE_PRESS_WINDOW` in `engine.py`).

### Shift layer (selected keys)

| Key + Shift | Output | Note |
|-------------|--------|------|
| Q | َ | fatha |
| W | ً | tanwin fath |
| E | ِ | kasra |
| R | ٍ | tanwin kasr |
| T | ُ | damma |
| Y | ٌ | tanwin damm |
| U | ْ | sukun |
| I | ّ | shadda |
| C | ئ | |
| V | ء | |
| B | أ | |
| N | إ | |
| M | ؤ | |
| / | ؟ | Arabic question mark |
| 5 | ٪ | Arabic percent sign |

### Alt layer (selected keys)

| Key + Alt | Output |
|-----------|--------|
| S | ے yeh barree |
| D | ی Farsi yeh |
| F | پ |
| C | ڈ |
| V | ڑ |
| B | ژ |
| J | ٹ |
| K | ں |
| ; | گ |
| I | ھ |
| O | ہ |
| P | چ |
