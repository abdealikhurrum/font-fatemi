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
