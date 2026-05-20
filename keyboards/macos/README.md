# Lisan ud Dawat — macOS Keyboard

Two options are available. The **keylayout bundle** is simpler but only remaps keys. The **IMKit app** adds double-press ligature input and a settings menu.

---

## Option A — Keylayout Bundle (simpler)

### Installation

1. Copy the bundle to your keyboard layouts folder:
   ```
   cp -r keyboards/mac-ukulele/lsdMac.bundle ~/Library/Keyboard\ Layouts/
   ```
2. Log out and back in (or restart).
3. Open **System Settings → Keyboard → Input Sources** and click **+**.
4. Search for **"Lisan"** or scroll to **Arabic → Others** to find *Lisan ud Dawat - Mac* and *Lisan ud Dawat - AK*.
5. Add the layout and select it from the Input Sources menu bar icon.

### Layouts

- **Lisan ud Dawat - Mac** — standard LSD layout
- **Lisan ud Dawat - AK** — alternate layout

---

## Option B — IMKit App (double-press, settings menu)

### Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build)

### Build

```
open keyboards/macos/LSDKeyboard/LSDKeyboard.xcodeproj
```

Select the **LSDKeyboard** scheme, set destination to **My Mac**, then **Product → Build** (⌘B). The built app appears at:
```
~/Library/Developer/Xcode/DerivedData/LSDKeyboard-*/Build/Products/Debug/LSDKeyboard.app
```

### Install

1. Copy the built app to the Input Methods folder:
   ```
   cp -r /path/to/LSDKeyboard.app ~/Library/Input\ Methods/
   ```
2. Log out and back in (or run the commands below to refresh without logging out):
   ```
   killall -9 TextInputMenuAgent
   /System/Library/CoreServices/TextInputMenuAgent.app/Contents/MacOS/TextInputMenuAgent &
   ```
3. Open **System Settings → Keyboard → Input Sources** and click **+**.
4. Search for **"Lisan"** — the keyboard will be listed under **Arabic**.
5. Add it and select it from the Input Sources menu bar icon.

### Features

- **Double-press** — press the same key twice quickly to insert the secondary character (ligature). The delay is configurable in the menu bar settings.
- **Settings menu** — click *Lisan ud Dawat* in the Input Sources menu bar icon to switch layout (LSD / Arabic Standard / CRULP Urdu), toggle double-press, adjust delay, and choose alef/yeh styles.

### Uninstall

```
rm -rf ~/Library/Input\ Methods/LSDKeyboard.app
killall -9 TextInputMenuAgent
/System/Library/CoreServices/TextInputMenuAgent.app/Contents/MacOS/TextInputMenuAgent &
```
Then remove it from System Settings → Keyboard → Input Sources.

---

## Troubleshooting

**Keyboard doesn't appear in the picker after installation**
- Make sure you logged out and back in (or ran the `killall TextInputMenuAgent` commands above).
- Verify the app is in `~/Library/Input Methods/` (not `/Applications/`).
- Check that macOS 13+ is running — the app requires Ventura or later.

**Keyboard appears but does nothing when selected**
- Open Console.app, filter by `LSDKeyboard`, and look for launch errors.
- Re-copy the app and repeat the `killall TextInputMenuAgent` refresh.
