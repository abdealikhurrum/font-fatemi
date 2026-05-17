import Foundation

// MARK: - Key Types

enum KeyType {
    case character
    case backspace
    case space
    case enter
    case numeric    // switch to 123 layer
    case abc        // switch back to letters
    case globe      // switch system input mode
}

// MARK: - Key Width

enum KeyWidth {
    case standard
    case wide
    case extraWide
    case flexible
    case fixed(CGFloat)
}

// MARK: - Key Data

struct KeyData {
    let primary: String
    let secondary: String       // small char shown on key; double-tap inserts this
    let alternates: [String]    // long-press popup
    let type: KeyType
    let width: KeyWidth

    init(
        _ primary: String,
        secondary: String = "",
        alternates: [String] = [],
        type: KeyType = .character,
        width: KeyWidth = .standard
    ) {
        self.primary    = primary
        self.secondary  = secondary
        self.alternates = alternates
        self.type       = type
        self.width      = width
    }
}

// MARK: - Keyboard Layer

struct KeyboardLayer {
    let id: String
    let rows: [[KeyData]]
}

// MARK: - Layout Definition
// Based on keyboards/keyman/lsd.kmn
//
// Secondaries — two tiers:
//   Official LSD double-press rules (lsd.kmn lines 57-64):
//     سس→ے  ضض→ٹ  طط→ں  ظظ→ہ  حح→چ  ثث→پ  كك→گ
//   Extended quick-access secondaries:
//     اا→أ  هه→ھ  يي→ئ  رر→ڑ  دد→ڈ  ةة→ۃ
//
// Long-press alternates are ordered by frequency so the first item is
// quickest to reach (slide right / nearest target in the popup).

enum KeyboardLayoutData {

    // ------------------------------------------------------------------ default

    static let defaultLayer = KeyboardLayer(id: "default", rows: [
        // Row 1 — 11 keys
        [
            KeyData("ض", secondary: "ٹ"),                                       // ضض → ٹ
            KeyData("ص"),
            KeyData("ث", secondary: "پ"),                                       // ثث → پ
            KeyData("ق"),
            KeyData("ف"),
            KeyData("غ"),
            KeyData("ع"),
            KeyData("ه", secondary: "ھ",  alternates: ["ـہـ", "ـہ", "ۂ"]),    // هه → ھ
            KeyData("خ"),
            KeyData("ح", secondary: "چ"),                                       // حح → چ
            KeyData("ج", alternates: ["چ", "چھے"]),
        ],
        // Row 2 — 10 keys
        [
            KeyData("ش"),
            KeyData("س", secondary: "ے"),                                       // سس → ے
            KeyData("ي", secondary: "ئ",  alternates: ["ئ", "ى", "ے"]),        // يي → ئ
            KeyData("ب"),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ", "لاٰ"]),
            KeyData("ا", secondary: "أ",  alternates: ["اٰ", "آ", "إ", "أ"]), // اا → أ; اٰ first in popup
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData("ك", secondary: "گ",  alternates: ["گ"]),                   // كك → گ
        ],
        // Row 3 — 9 chars + backspace
        [
            KeyData("ذ"),
            KeyData("ظ", secondary: "ہ"),                                       // ظظ → ہ
            KeyData("ؤ", alternates: ["ۚ", "ۨ"]),
            KeyData("ر", secondary: "ڑ",  alternates: ["ڑ"]),                   // رر → ڑ
            KeyData("ز", alternates: ["ژ"]),
            KeyData("و"),
            KeyData("ط", secondary: "ں"),                                       // طط → ں
            KeyData("د", secondary: "ڈ",  alternates: ["ڈ"]),                   // دد → ڈ
            KeyData("ة", secondary: "ۃ"),                                       // ةة → ۃ
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4 — utility row
        // Space long-press → diacritics (harakat)
        // Period long-press → punctuation + ء
        [
            KeyData("🌐", type: .globe,   width: .fixed(44)),
            KeyData("١٢٣", type: .numeric, width: .fixed(80)),
            KeyData(".",
                    alternates: [".", "!", "؟", "،", "؛", "٬", "ء"],
                    width: .fixed(44)),
            KeyData(" ",
                    alternates: ["َ", "ِ", "ُ", "ْ", "ٰ", "ً", "ٍ", "ٌ"],
                    type: .space, width: .flexible),
            KeyData("↵",  type: .enter,   width: .fixed(80)),
        ],
    ])

    // ------------------------------------------------------------------ numeric

    static let numericLayer = KeyboardLayer(id: "numeric", rows: [
        // Row 1 — digits
        [
            KeyData("1", alternates: ["١", "૧"]),
            KeyData("2", alternates: ["٢", "૨"]),
            KeyData("3", alternates: ["٣", "૩"]),
            KeyData("4", alternates: ["٤", "૪"]),
            KeyData("5", alternates: ["٥", "૫"]),
            KeyData("6", alternates: ["٦", "૬"]),
            KeyData("7", alternates: ["٧", "૭"]),
            KeyData("8", alternates: ["٨", "૮"]),
            KeyData("9", alternates: ["٩", "૯"]),
            KeyData("0", alternates: ["٠", "૰"]),
        ],
        // Row 2 — symbols
        [
            KeyData("$", alternates: ["₨", "¥", "؋", "؈", "૱"]),
            KeyData("#"),
            KeyData("%", alternates: ["٪"]),
            KeyData("^"),
            KeyData("<"),
            KeyData(">"),
            KeyData("+", alternates: ["×"]),
            KeyData("="),
            KeyData("*", alternates: ["٭"]),
            KeyData("-", alternates: ["÷", "_"]),
        ],
        // Row 3 — literary / poetry marks
        [
            KeyData("@"),
            KeyData("("),
            KeyData(")"),
            KeyData("؏"),
            KeyData("ؔ"),
            KeyData("؃"),
            KeyData("؂", alternates: ["؎"]),
            KeyData("؁", alternates: ["؄"]),
            KeyData("؀", alternates: ["۝", "۩"]),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4
        [
            KeyData("ا ب ج", type: .abc, width: .fixed(80)),
            KeyData(" ", type: .space, width: .flexible),
            KeyData("↵", type: .enter, width: .fixed(80)),
        ],
    ])
}
