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
// Secondary characters follow the official LSD double-press convention from lsd.kmn lines 57-64:
//   سس→ے  ضض→ٹ  طط→ں  ظظ→ہ  حح→چ  ثث→پ  كك→گ
// All other keys have no secondary (double-tap just types the primary twice).

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
            KeyData("ه", alternates: ["ـہـ", "ـہ", "ھ", "ة", "ۂ"]),
            KeyData("خ"),
            KeyData("ح", secondary: "چ"),                                       // حح → چ
            KeyData("ج", alternates: ["چ", "چھے"]),
        ],
        // Row 2 — 10 keys
        [
            KeyData("ش"),
            KeyData("س", secondary: "ے"),                                       // سس → ے
            KeyData("ي", alternates: ["ئ", "ى", "ے"]),
            KeyData("ب"),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ", "لاٰ"]),
            KeyData("ا", alternates: ["أ", "إ", "آ", "اٰ"]),
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData("ك", secondary: "گ",  alternates: ["گ"]),                   // كك → گ
        ],
        // Row 3 — 8 chars + backspace (no shift key)
        [
            KeyData("ذ"),
            KeyData("ظ", secondary: "ہ"),                                       // ظظ → ہ
            KeyData("ؤ", alternates: ["ۚ", "ۨ"]),
            KeyData("ر", alternates: ["ڑ"]),
            KeyData("ز", alternates: ["ظ", "ژ"]),
            KeyData("و", alternates: ["ة", "ۃ"]),
            KeyData("ط", secondary: "ں"),                                       // طط → ں
            KeyData("د", alternates: ["ڈ", "ذ"]),
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
