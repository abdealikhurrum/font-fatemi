# Lisan ud Dawat — iOS Keyboard Extension

A native iOS custom keyboard for Lisan ud Dawat (Arabic script), matching the layout in `keyboards/keyman/lsd-layout.js`.

## Features

- **Three layers** — Default (Arabic characters), Shift (diacritics + honorifics), Numeric (digits + symbols)
- **Long-press alternates** — Hold any key with variants to see a popup with alternate characters (matches the `sk` entries in the Keyman layout)
- **Repeat-delete** — Hold backspace for continuous deletion
- **RTL-ready** — marked as PrefersRightToLeft in Info.plist
- **FatemiMaqala font** — used automatically if the font is bundled in the app; falls back to the system Arabic font

## Layer Layout

### Default

```
Row 1:  ض  ص  ث  ق  ف  غ  ع  ه  خ  ح  ج
Row 2:  ش  س  ي  ب  ل  ا  ت  ن  م  ك
Row 3: [⇧] ذ  ظ  ؤ  ر  ز  و  ط  د [⌫]
Row 4: [١٢٣]  ى  اعراب  [space]  .  ء  [↵]
```

### Shift

```
Row 1:  َ   ُ   ٗ   ؕ   ؐ   ؑ  ﷺ  ھ  ژ  چھے  چ
Row 2:  ِ   ٰ   ے  پ  ﷻ  ؓ  ـ  ،  ں  گ
Row 3: [⇧] ْ   ٖ   ۚ   ڑ   ؒ   ٹ  ڈ [⌫]
Row 4: [١٢٣]  [space]  ۞  [↵]
```

### Numeric

```
Row 1:  1  2  3  4  5  6  7  8  9  0
Row 2:  $  #  %  ^  <  >  +  =  *  -
Row 3:  @  (  )  ؏  ؔ  ؃  ؂  ؁  ؀ [⌫]
Row 4: [ا ب ج]  [space]  [↵]
```

## Xcode Project Setup

1. **Create a new Xcode project**
   - Product: *App* → name it `LisanUdDawat`
   - Bundle ID: `com.yourorg.LisanUdDawat`

2. **Add the keyboard extension target**
   - File → New → Target → Custom Keyboard Extension
   - Product Name: `LisanUdDawatKeyboard`
   - Bundle ID: `com.yourorg.LisanUdDawat.Keyboard`

3. **Replace generated files**
   - Replace `LisanUdDawatKeyboard/KeyboardViewController.swift` with the file from this folder
   - Add `KeyData.swift`, `KeyboardView.swift`, `KeyButton.swift`, `LongPressPopupView.swift` to the extension target
   - Replace `LisanUdDawatKeyboard/Info.plist` with the one in this folder
   - Replace the app's `AppDelegate.swift` and `ViewController.swift` with the files from `LisanUdDawatApp/`

4. **Bundle the font (optional but recommended)**
   - Add `FatemiMaqala-Regular.ttf` to both targets (app + extension)
   - In both `Info.plist` files add:
     ```xml
     <key>UIAppFonts</key>
     <array>
         <string>FatemiMaqala-Regular.ttf</string>
     </array>
     ```

5. **Enable App Groups (if you want shared settings)**
   - Add the `App Groups` capability to both targets with the same group ID
   - Set `RequestsOpenAccess` to `YES` in the extension's Info.plist

6. **Build & run** on a real device (keyboard extensions do not work in the Simulator for text input in other apps)

7. **Enable the keyboard** on the device:
   *Settings → General → Keyboard → Keyboards → Add New Keyboard… → Lisan ud Dawat*

## File Structure

```
keyboards/ios/
├── README.md                               ← this file
├── LisanUdDawatApp/
│   ├── AppDelegate.swift                   ← minimal containing app
│   ├── ViewController.swift                ← setup-instructions screen
│   └── Info.plist
└── LisanUdDawatKeyboard/
    ├── KeyboardViewController.swift        ← UIInputViewController subclass
    ├── KeyData.swift                       ← layout data + key model
    ├── KeyboardView.swift                  ← keyboard container view
    ├── KeyButton.swift                     ← individual key with long-press
    ├── LongPressPopupView.swift            ← alternate-character popup
    └── Info.plist                          ← extension manifest
```
