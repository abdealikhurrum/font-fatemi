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

    // diacriticLayer: letter rows hold diacritics (symmetric); number row holds BiDi controls.
    //
    // Letter key pairings (left ↔ right, Mac key codes):
    //   A(0)  ↔ ;(41)   S(1)  ↔ L(37)   D(2)  ↔ K(40)   F(3)  ↔ J(38)   G(5)  ↔ H(4)
    //   Q(12) ↔ P(35)   W(13) ↔ O(31)   E(14) ↔ I(34)   R(15) ↔ U(32)   T(16) ↔ Y(17)
    //   [(33) ↔ ](30)   B(11) ↔ N(45)
    //
    // Number row (physical position → code):  1→18  2→19  3→20  4→21  5→23  6→22  7→26
    //   Keys 8(28) and 9(25) are Sanah/Safha subtending triggers (see diacriticSubtendingLayer).
    private static let diacriticLayer: [Int: String] = [
        // A / ;  — fatha
        0: "\u{064E}", 41: "\u{064E}",
        // S / L  — kasra
        1: "\u{0650}", 37: "\u{0650}",
        // D / K  — damma
        2: "\u{064F}", 40: "\u{064F}",
        // F / J  — sukun
        3: "\u{0652}", 38: "\u{0652}",
        // G / H  — shadda
        5: "\u{0651}", 4: "\u{0651}",
        // Q / P  — fathatan
        12: "\u{064B}", 35: "\u{064B}",
        // W / O  — kasratan
        13: "\u{064D}", 31: "\u{064D}",
        // E / I  — dammatan
        14: "\u{064C}", 34: "\u{064C}",
        // R / U  — kharo zabar (superscript alef)
        15: "\u{0670}", 32: "\u{0670}",
        // T / Y  — maddah
        16: "\u{0653}", 17: "\u{0653}",
        // [ / ]  — hamza above
        33: "\u{0654}", 30: "\u{0654}",
        // B / N  — hamza below
        11: "\u{0655}", 45: "\u{0655}",
        // Number row — BiDi control characters
        18: "\u{200E}",   // 1 → LRM  (Left-to-Right Mark)
        19: "\u{200F}",   // 2 → RLM  (Right-to-Left Mark)
        20: "\u{2066}",   // 3 → LRI  (Left-to-Right Isolate)
        21: "\u{2067}",   // 4 → RLI  (Right-to-Left Isolate)
        23: "\u{2069}",   // 5 → PDI  (Pop Directional Isolate)
        22: "\u{200D}",   // 6 → ZWJ  (Zero Width Joiner)
        26: "\u{200C}",   // 7 → ZWNJ (Zero Width Non-Joiner)
    ]

    // Subtending mark triggers (Caps Lock + 8 / 9).
    // Inserting one of these characters puts the IME into digit-collection mode;
    // the mark visually subtends over the following digit sequence.
    private static let diacriticSubtendingLayer: [Int: String] = [
        28: "\u{0601}",   // 8 → U+0601 ARABIC SIGN SANAH  (year subtending mark)
        25: "\u{0603}",   // 9 → U+0603 ARABIC SIGN SAFHA  (page subtending mark)
    ]

    static func diacriticSubtending(forCode code: Int) -> String? {
        return diacriticSubtendingLayer[code]
    }

    // diacriticArrowLayer: maps code to NSResponder selector string (symmetric).
    //   Z(6)  / /(44) → moveLeft:
    //   X(7)  / .(47) → moveUp:
    //   C(8)  / ,(43) → moveDown:
    //   V(9)  / M(46) → moveRight:
    private static let diacriticArrowLayer: [Int: String] = [
        6: "moveLeft:",  44: "moveLeft:",
        7: "moveUp:",    47: "moveUp:",
        8: "moveDown:",  43: "moveDown:",
        9: "moveRight:", 46: "moveRight:",
    ]

    static func diacriticChar(forCode code: Int) -> String? {
        return diacriticLayer[code]
    }

    static func diacriticArrow(forCode code: Int) -> String? {
        return diacriticArrowLayer[code]
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
