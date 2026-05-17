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
    let secondary: String       // shown small on key; double-tap inserts this instead
    let alternates: [String]    // shown in long-press popup
    let type: KeyType
    let width: KeyWidth

    init(
        _ primary: String,
        secondary: String = "",
        alternates: [String] = [],
        type: KeyType = .character,
        width: KeyWidth = .standard
    ) {
        self.primary   = primary
        self.secondary = secondary
        self.alternates = alternates
        self.type  = type
        self.width = width
    }
}

// MARK: - Keyboard Layer

struct KeyboardLayer {
    let id: String
    let rows: [[KeyData]]
}

// MARK: - Layout Definition
// Based on keyboards/keyman/lsd-layout.js (phone layer).
// The shift layer has been removed. Secondary characters (top-left of each key)
// are accessed by double-tapping — no explicit shift key needed.

enum KeyboardLayoutData {

    // ------------------------------------------------------------------ default

    static let defaultLayer = KeyboardLayer(id: "default", rows: [
        // Row 1 — 11 keys
        [
            KeyData("ض", secondary: "َ"),                                           // fatha
            KeyData("ص", secondary: "ُ"),                                           // damma
            KeyData("ث", secondary: "ٗ"),                                           // inverted damma
            KeyData("ق", secondary: "ؕ"),
            KeyData("ف", secondary: "ؐ"),
            KeyData("غ", secondary: "ؑ"),
            KeyData("ع", secondary: "ﷺ"),                                          // SAW honorific
            KeyData("ه", secondary: "ھ",  alternates: ["ـہـ", "ـہ", "ھ", "ة", "ۂ"]),
            KeyData("خ", secondary: "ژ"),
            KeyData("ح", secondary: "چھے"),
            KeyData("ج", secondary: "چ",  alternates: ["چ", "چھے"]),
        ],
        // Row 2 — 10 keys
        [
            KeyData("ش", secondary: "ِ"),                                           // kasra
            KeyData("س", secondary: "ٰ"),                                           // superscript alef
            KeyData("ي", secondary: "ے",  alternates: ["ئ", "ى", "ے"]),
            KeyData("ب", secondary: "پ"),
            KeyData("ل", secondary: "ﷻ",  alternates: ["لا", "لأ", "لإ", "لآ", "لاٰ"]),
            KeyData("ا", secondary: "ؓ",  alternates: ["أ", "إ", "آ", "اٰ"]),
            KeyData("ت", secondary: "ـ"),                                           // tatweel
            KeyData("ن", secondary: "،"),                                           // Arabic comma
            KeyData("م", secondary: "ں"),
            KeyData("ك", secondary: "گ",  alternates: ["گ"]),
        ],
        // Row 3 — 8 chars + backspace (no shift key)
        [
            KeyData("ذ", secondary: "ْ"),                                           // sukun
            KeyData("ظ", secondary: "ٖ"),                                           // subscript alef
            KeyData("ؤ", secondary: "ۚ",  alternates: ["ۚ", "ۨ"]),
            KeyData("ر", secondary: "ڑ",  alternates: ["ڑ"]),
            KeyData("ز", secondary: "ؒ",  alternates: ["ظ", "ژ"]),
            KeyData("و", secondary: "ٹ",  alternates: ["ة", "ۃ"]),
            KeyData("ط", secondary: "ڈ"),
            KeyData("د",                  alternates: ["ڈ", "ذ"]),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4 — utility row
        [
            KeyData("١٢٣", type: .numeric, width: .fixed(80)),
            KeyData("ى",   secondary: "۞"),
            KeyData("", alternates: ["َ", "ِ", "ُ", "ْ", "ٰ", "ً", "ٍ", "ٌ"], width: .fixed(30)),
            KeyData(" ",   type: .space, width: .fixed(80)),
            KeyData(".",   alternates: [".", "!", "؟", "،", "؛", "٬"], width: .fixed(44)),
            KeyData("ء"),
            KeyData("↵",   type: .enter, width: .fixed(80)),
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
