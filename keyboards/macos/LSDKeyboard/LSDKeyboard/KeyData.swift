import Foundation

// MARK: - Layout data (ported from iOS LSDLearningKB/KeyData.swift)
// The macOS IME operates on a physical Arabic keyboard, so KeyType and KeyWidth
// are retained for completeness but only .character keys participate in the
// double-press lookup; all other keys are passed through to the app.

enum KeyType {
    case character
    case backspace, space, enter
    case numeric, abc, globe, emoji, diacritic
    case cursorLeft, cursorRight
}

struct KeyData {
    let primary: String
    let secondary: String
    let alternates: [String]
    let type: KeyType

    init(_ primary: String,
         secondary: String = "",
         alternates: [String] = [],
         type: KeyType = .character) {
        self.primary    = primary
        self.secondary  = secondary
        self.alternates = alternates
        self.type       = type
    }
}

// MARK: - Double-press lookup
//
// Returns the secondary character for a double-press, honouring current settings:
//   - doublePressEnabled    — returns nil for everything when off
//   - selectedLayout        — switches between LSD/Arabic-Standard map and CRULP map
//   - doubleAlefStyle       — اا → اٰ (kharo zabar, default) or آ (alef madda)
//   - urduYehStyle          — which code-point is "yeh" in the CRULP map
//
// LSD / Arabic-Standard secondaries:
//   Official rules (lsd.kmn):  سس→ے  ضض→ٹ  طط→ں  ظظ→ہ  حح→چ  ثث→پ  كك→گ
//   Extended:                  اا→اٰ  هه→ھ  يي→ئ  رر→ڑ  دد→ڈ  ةة→ۃ  جج→چھے
//
// CRULP Urdu secondaries (phonetic positions):
//   عع→غ  رر→ڑ  تت→ٹ  حح→خ  دد→ڈ  ہہ→ھ  زز→ذ  شش→ض  نن→ں

extension KeyData {
    static func secondary(for char: String) -> String? {
        guard KeyboardSettings.doublePressEnabled else { return nil }
        switch KeyboardSettings.selectedLayout {
        case .crulpUrdu: return crulpSecondary(for: char)
        default:         return lsdSecondary(for: char)
        }
    }

    private static func lsdSecondary(for char: String) -> String? {
        let alef = KeyboardSettings.doubleAlefStyle == .alefMadda ? "آ" : "اٰ"
        switch char {
        case "ض": return "ٹ"
        case "ث": return "پ"
        case "ه": return "ھ"
        case "ح": return "چ"
        case "ج": return "چھے"
        case "س": return "ے"
        case "ي": return "ئ"
        case "ا": return alef
        case "ك": return "گ"
        case "ط": return "ں"
        case "ر": return "ڑ"
        case "ة": return "ۃ"
        case "د": return "ڈ"
        case "ظ": return "ہ"
        default:  return nil
        }
    }

    private static func crulpSecondary(for char: String) -> String? {
        switch char {
        case "ع": return "غ"
        case "ر": return "ڑ"
        case "ت": return "ٹ"
        case "ح": return "خ"
        case "د": return "ڈ"
        case "ہ": return "ھ"   // U+06C1 he goal → do chashmi he
        case "ز": return "ذ"
        case "ش": return "ض"
        case "ن": return "ں"
        default:  return nil
        }
    }
}

// MARK: - Key-code → character mapping

extension KeyData {

    // Returns the Arabic/Urdu character for a physical key code + modifier combination,
    // honouring the currently selected layout. Returns nil for unmapped keys (function
    // keys, arrows, modifier-only presses, etc.) so the IME can pass them through.
    static func char(forCode code: Int, shift: Bool, option: Bool) -> String? {
        let layout = KeyboardSettings.selectedLayout
        let normalBase = layout == .macLsd ? macLsdNormalLayer : normalLayer
        let shiftBase  = layout == .macLsd ? macLsdShiftLayer  : shiftLayer
        let base: [Int: String]
        switch (shift, option) {
        case (true,  true):  base = shiftOptionLayer
        case (false, true):  base = optionLayer
        case (true,  false): base = shiftBase
        default:             base = normalBase
        }
        guard var ch = base[code] else { return nil }
        if layout == .crulpUrdu,
           let swapped = crulpPrimarySwap[ch] { ch = swapped }
        return ch
    }

    // Characters that differ between LSD (Windows PC) and CRULP Urdu in the primary layer.
    // Yeh entry is conditional on urduYehStyle: farsi yeh (U+06CC) is default; arabic yeh
    // (U+064A) leaves the base character unchanged, so we omit it from the swap map.
    private static var crulpPrimarySwap: [String: String] {
        var map: [String: String] = ["ه": "ہ", "ك": "ک", "ة": "ۃ"]
        if KeyboardSettings.urduYehStyle == .farsiYeh { map["ي"] = "ی" }
        return map
    }

    // MARK: Windows LSD layers (default — maqalaAra.klc)

    // Layer 2 (no modifier) — Windows LSD / maqalaAra.klc
    private static let normalLayer: [Int: String] = [
        0: "ش",  1: "س",  2: "ي",  3: "ب",  4: "ا",  5: "ل",
        6: "ئ",  7: "ء",  8: "ؤ",  9: "ر",  11: "لا",
        12: "ض", 13: "ص", 14: "ث", 15: "ق", 16: "ف", 17: "غ",
        18: "١", 19: "٢", 20: "٣", 21: "٤", 22: "٦", 23: "٥",
        24: "=",  25: "٩", 26: "٧", 27: "-",  28: "٨", 29: "٠",
        30: "د", 31: "خ", 32: "ع", 33: "ج",  34: "ه", 35: "ح",
        37: "م", 38: "ت", 39: "ط", 40: "ن",  41: "ك",
        42: "\\", 43: "و", 44: "ظ",  45: "ى", 46: "ة", 47: "ز",
        50: "ذ",
    ]

    // Layer 3 (shift) — sourced from the Windows LSD keyboard (maqalaAra.klc)
    private static let shiftLayer: [Int: String] = [
        // QWERTY row
        12: "\u{064E}", 13: "\u{064B}", 14: "\u{064F}", 15: "\u{064C}",
        16: "\u{06A4}", 17: "\u{0625}",
        32: "\u{0657}", 34: "\u{06BE}",
        31: "\u{0679}", 35: "\u{06C1}",
        33: "\u{0686}", 30: "\u{0688}",
        // ASDF row
        0: "\u{0650}", 1: "\u{064D}", 2: "\u{06D2}", 3: "\u{067E}",
        4: "\u{0623}", 38: "\u{0640}", 40: "\u{060C}", 37: "\u{06BA}",
        41: "\u{06AF}", 39: "\"",
        // Backtick
        50: "\u{0651}",
        // ZXCV row
        6: "\u{0670}", 7: "\u{0652}", 8: "\u{0656}",
        9: "\u{0691}", 11: ":", 45: "\u{0622}", 46: "\u{06C3}",
        43: "\u{0613}", 47: ".", 44: "\u{061F}",
        42: "|",
        // Number row shifts
        18: "!", 19: "@", 20: "#", 21: "$", 22: "^", 23: "٪",
        24: "+", 25: ")", 26: "&", 27: "_", 28: "*", 29: "(",
    ]

    // Layer 4 (option) — sourced from the LSD Mac keylayout
    private static let optionLayer: [Int: String] = [
        49: "\u{00A0}",   // Option+Space → NBSP (non-breaking space)
        0: "\u{0614}",
        1: "ے",  2: "ی",  3: "پ",
        4: "\u{0670}", 5: "\u{0653}", 6: "\u{06DA}", 7: "\u{06E8}",
        8: "ڈ",  9: "ڑ",  11: "ژ",
        12: "\u{2018}", 13: "\u{2019}", 14: "\u{201C}", 15: "\u{201D}",
        16: "\u{0657}", 17: "ڤ",
        19: "\u{0610}", 22: "\u{0671}",
        25: "ۂ",  26: "۞",  27: "_",  28: "\u{0655}",
        30: "ۃ",  31: "ہ",  32: "\u{0611}", 33: "چ",  34: "ھ",
        38: "ٹ",  40: "ں",  41: "گ",
        44: "÷",  45: "\u{0613}", 46: "\u{0656}",
    ]

    // Layer 5 (shift+option) — sourced from the LSD Mac keylayout
    private static let shiftOptionLayer: [Int: String] = [
        49: "\u{200C}",   // Shift+Option+Space → ZWNJ (zero-width non-joiner)
        1: "ے",  2: "ی",  3: "پ",
        8: "ڈ",  9: "ڑ",  11: "ژ",
        17: "ڤ", 18: "ظ",
        27: "_",
        31: "\u{06D5}", 32: "\u{06D5}", 33: "چ",
        38: "ٹ",  40: "ں",  41: "ک",
        44: "÷",
    ]

    // MARK: Mac LSD layers (Lisan ud Dawat - Mac.keylayout)

    // Layer 2 (no modifier) — Mac LSD keylayout index 2
    private static let macLsdNormalLayer: [Int: String] = [
        0: "ش",  1: "س",  2: "ي",  3: "ب",  4: "ا",  5: "ل",
        6: "ظ",  7: "ط",  8: "ذ",  9: "د",  11: "ز",
        12: "ض", 13: "ص", 14: "ث", 15: "ق", 16: "غ", 17: "ف",
        18: "١", 19: "٢", 20: "٣", 21: "٤", 22: "٦", 23: "٥",
        24: "=",  25: "٩", 26: "٧", 27: "-",  28: "٨", 29: "٠",
        30: "ة", 31: "خ", 32: "ع", 33: "ج",  34: "ه", 35: "ح",
        37: "م", 38: "ت", 39: "؛", 40: "ن",  41: "ك",
        42: "\\", 43: "،", 44: "/",  45: "ر", 46: "و", 47: ".",
        50: "ـ",
    ]

    // Layer 3 (shift) — Mac LSD keylayout index 3
    private static let macLsdShiftLayer: [Int: String] = [
        0: "»",  1: "«",  2: "ى",  4: "آ",  6: "'",
        8: "ئ",  9: "ء",  11: "أ",
        12: "\u{064E}", 13: "\u{064B}", 14: "\u{0650}",
        15: "\u{064D}", 16: "\u{064C}", 17: "\u{064F}",
        18: "!", 19: "@",  20: "#",  21: "$", 22: "^",  23: "٪",
        24: "+", 25: ")",  26: "&",  27: "ـ", 28: "*",  29: "(",
        30: "{", 31: "\u{0652}", 32: "\u{0652}", 33: "}",
        34: "\u{0651}", 35: "[",
        37: "\u{066C}", 39: "\"", 40: "\u{066B}",
        41: ":", 42: "|",  43: ">", 44: "؟", 45: "إ", 46: "ؤ", 47: "<",
    ]

    // MARK: - Diacritic mode layers (Caps Lock)
    //
    // Layout philosophy: all base harakat reachable from the LEFT hand alone.
    //
    //   Left QWERTY:  Q=fatha  W=fathatan  E=damma  R=dammatan  T=hamza-above
    //   Left ASDF:    A=kasra  S=kasratan  D=maddah  F=kharo-zabar  G=hamza-below
    //   Left ZXCV:    Z=shadda  X=sukun  C=inv-damma  V=tatweel  B=ZWJ
    //   Backtick:     takhallus
    //
    //   Right QWERTY: small Quranic diacritics (Y U I O P [ ])
    //   Right ASDF:   small Quranic diacritics (H J K L) + SAWS/AS marks (; ')
    //   Right ZXCV:   document marks (N=ayah  M=rub-el-hizb  ,=sajda  .=sanah  /=safha)
    //   Number row:   Quranic pause/decoration marks (U+06D6 – U+06E8)
    //
    // Mac virtual key codes used below:
    //   `=50  1=18 2=19 3=20 4=21 5=23 6=22 7=26 8=28 9=25 0=29 -=27 ==24
    //   Q=12 W=13 E=14 R=15 T=16 Y=17 U=32 I=34 O=31 P=35 [=33 ]=30
    //   A=0  S=1  D=2  F=3  G=5  H=4  J=38 K=40 L=37 ;=41 '=39
    //   Z=6  X=7  C=8  V=9  B=11 N=45 M=46 ,=43 .=47 /=44
    private static let diacriticLayer: [Int: String] = [
        // ── Number row — Quranic pause/decoration marks ───────────────────
        18: "\u{06D6}",   // 1 → small high lig ṣad-lam-alef-maksura
        19: "\u{06D7}",   // 2 → small high lig qaf-lam-alef-maksura
        20: "\u{06D8}",   // 3 → small high meem initial form
        21: "\u{06D9}",   // 4 → small high lam alef
        23: "\u{06DA}",   // 5 → small high jeem
        22: "\u{06DB}",   // 6 → small high three dots
        26: "\u{06DC}",   // 7 → small high seen
        28: "\u{06DF}",   // 8 → small high rounded zero
        25: "\u{06E0}",   // 9 → small high upright rectangular zero
        29: "\u{06E1}",   // 0 → small high dotless head of khah
        27: "\u{06E2}",   // - → small high meem isolated
        24: "\u{06E8}",   // = → small high noon

        // ── QWERTY row ────────────────────────────────────────────────────
        // Left hand — base harakat
        12: "\u{064E}",   // Q → fatha
        13: "\u{064B}",   // W → fathatan
        14: "\u{064F}",   // E → damma
        15: "\u{064C}",   // R → dammatan
        16: "\u{0654}",   // T → hamza above
        // Right hand — small Quranic diacritics
        17: "\u{0618}",   // Y → arabic small fatha
        32: "\u{061A}",   // U → arabic small kasra
        34: "\u{0619}",   // I → arabic small damma
        31: "\u{0615}",   // O → arabic small high tah
        35: "\u{06E4}",   // P → arabic small high madda
        33: "\u{06E3}",   // [ → arabic small low seen
        30: "\u{06ED}",   // ] → arabic small low meem

        // ── ASDF row ──────────────────────────────────────────────────────
        // Left hand — base harakat (continued)
        0:  "\u{0650}",   // A → kasra
        1:  "\u{064D}",   // S → kasratan
        2:  "\u{0653}",   // D → maddah above
        3:  "\u{0670}",   // F → kharo zabar (superscript alef)
        5:  "\u{0655}",   // G → hamza below
        // Right hand — small Quranic diacritics (continued) + marks
        4:  "\u{06E7}",   // H → arabic small high yeh
        38: "\u{06E5}",   // J → arabic small waw
        40: "\u{06E6}",   // K → arabic small yeh
        37: "\u{0616}",   // L → arabic small high lig alef-lam-yeh
        41: "\u{0610}",   // ; → SAWS mark
        39: "\u{0611}",   // ' → AS mark

        // ── ZXCV row ──────────────────────────────────────────────────────
        50: "\u{0614}",   // ` → takhallus (U+0614 arabic sign high waqf)
        // Left hand — base harakat (continued) + common joiners
        6:  "\u{0651}",   // Z → shadda (tashdeed)
        7:  "\u{0652}",   // X → sukun
        8:  "\u{0657}",   // C → arabic inverted damma
        9:  "\u{0640}",   // V → tatweel (kashida)
        11: "\u{200D}",   // B → ZWJ (zero-width joiner)
        // Right hand — document marks
        45: "\u{06DD}",   // N → end of ayah
        46: "\u{06DE}",   // M → rub el hizb
        43: "\u{06E9}",   // , → place of sajda
        47: "\u{0601}",   // . → sanah (year sign)
        44: "\u{0603}",   // / → safha (page sign)
    ]

    // Subtending mark triggers (Option layer, independent of Caps Lock).
    // Pressing one of these puts the IME into digit-collection mode;
    // the mark visually subtends over the following Arabic-Indic digit sequence.
    private static let optionSubtendingLayer: [Int: String] = [
        37: "\u{0601}",   // Option+L → U+0601 ARABIC SIGN SANAH  (year subtending mark)
        35: "\u{0603}",   // Option+P → U+0603 ARABIC SIGN SAFHA  (page subtending mark)
    ]

    static func optionSubtending(forCode code: Int) -> String? {
        return optionSubtendingLayer[code]
    }

    static func diacriticChar(forCode code: Int) -> String? {
        return diacriticLayer[code]
    }
}

// MARK: - Full layout (retained for reference; not rendered on macOS)

struct KeyboardLayer {
    let id: String
    let rows: [[KeyData]]
}

enum KeyboardLayoutData {

    static let defaultLayer = KeyboardLayer(id: "default", rows: [
        [
            KeyData("ض", secondary: "ٹ"),
            KeyData("ص"),
            KeyData("ث", secondary: "پ"),
            KeyData("ق"),
            KeyData("ف"),
            KeyData("غ"),
            KeyData("ع"),
            KeyData("ه", secondary: "ھ",  alternates: ["ـہـ", "ـہ", "ۂ"]),
            KeyData("خ"),
            KeyData("ح", secondary: "چ"),
            KeyData("ج", secondary: "چھے"),
        ],
        [
            KeyData("ش"),
            KeyData("س", secondary: "ے"),
            KeyData("ي", secondary: "ئ",  alternates: ["ے"]),
            KeyData("ب"),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ", "لاٰ"]),
            KeyData("ا", secondary: "اٰ", alternates: ["أ", "آ", "إ"]),
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData("ك", secondary: "گ",  alternates: ["گ"]),
            KeyData("ط", secondary: "ں"),
        ],
        [
            KeyData("ئ"),
            KeyData("ء"),
            KeyData("ؤ", alternates: ["ۚ", "ۨ"]),
            KeyData("ر", secondary: "ڑ",  alternates: ["ڑ"]),
            KeyData("ى"),
            KeyData("ة", secondary: "ۃ"),
            KeyData("و"),
            KeyData("ز", alternates: ["ژ", "ذ"]),
            KeyData("د", secondary: "ڈ",  alternates: ["ڈ"]),
            KeyData("ظ", secondary: "ہ"),
        ],
    ])
}
