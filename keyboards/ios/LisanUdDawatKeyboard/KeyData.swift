import Foundation

// MARK: - Key Types

enum KeyType {
    case character
    case shift
    case backspace
    case space
    case enter
    case numeric    // switch to 123
    case abc        // switch back to letters
    case globe      // switch input mode
}

// MARK: - Key Width

enum KeyWidth {
    case standard       // normal character key
    case wide           // e.g. shift/backspace
    case extraWide      // e.g. space bar
    case flexible       // fills remaining space
    case fixed(CGFloat) // explicit points
}

// MARK: - Key Data

struct KeyData {
    let primary: String
    let alternates: [String]
    let type: KeyType
    let width: KeyWidth

    init(
        _ primary: String,
        alternates: [String] = [],
        type: KeyType = .character,
        width: KeyWidth = .standard
    ) {
        self.primary = primary
        self.alternates = alternates
        self.type = type
        self.width = width
    }
}

// MARK: - Keyboard Layer

struct KeyboardLayer {
    let id: String
    let rows: [[KeyData]]
}

// MARK: - Layout Definition
// Based on keyboards/keyman/lsd-layout.js (phone layer)

enum KeyboardLayoutData {

    // ------------------------------------------------------------------ default

    static let defaultLayer = KeyboardLayer(id: "default", rows: [
        // Row 1 — 11 keys
        [
            KeyData("ض"),
            KeyData("ص"),
            KeyData("ث"),
            KeyData("ق"),
            KeyData("ف"),
            KeyData("غ"),
            KeyData("ع"),
            KeyData("ه", alternates: ["ـہـ", "ـہ", "ھ", "ة", "ۂ"]),
            KeyData("خ"),
            KeyData("ح"),
            KeyData("ج", alternates: ["چ", "چھے"]),
        ],
        // Row 2 — 10 keys (slightly indented on real iOS keyboard)
        [
            KeyData("ش"),
            KeyData("س"),
            KeyData("ي", alternates: ["ئ", "ى", "ے"]),
            KeyData("ب"),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ", "لاٰ"]),
            KeyData("ا", alternates: ["أ", "إ", "آ", "اٰ"]),
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData("ك", alternates: ["گ"]),
        ],
        // Row 3 — shift + 8 chars + backspace
        [
            KeyData("⇧", type: .shift, width: .wide),
            KeyData("ذ"),
            KeyData("ظ"),
            KeyData("ؤ", alternates: ["ۚ", "ۨ"]),
            KeyData("ر", alternates: ["ڑ"]),
            KeyData("ز", alternates: ["ظ", "ژ"]),
            KeyData("و", alternates: ["ة", "ۃ"]),
            KeyData("ط"),
            KeyData("د", alternates: ["ڈ", "ذ"]),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4 — utility row
        [
            KeyData("١٢٣", type: .numeric, width: .fixed(80)),
            KeyData("ى"),
            KeyData("اعراب", alternates: ["َ", "ِ", "ُ", "ْ", "ٰ", "ً", "ٍ", "ٌ"], width: .fixed(70)),
            KeyData(" ", type: .space, width: .flexible),
            KeyData(".", alternates: [".", "!", "؟", "،", "؛", "٬"], width: .fixed(44)),
            KeyData("ء"),
            KeyData("↵", type: .enter, width: .fixed(80)),
        ],
    ])

    // ------------------------------------------------------------------ shift

    static let shiftLayer = KeyboardLayer(id: "shift", rows: [
        // Row 1 — diacritics and honorifics
        [
            KeyData("َ"),   // fatha
            KeyData("ُ"),   // damma
            KeyData("ٗ"),   // inverted damma
            KeyData("ؕ"),   // small high rounded zero
            KeyData("ؐ"),   // small high ligature saad laam
            KeyData("ؑ"),   // small high upright rectangular zero
            KeyData("ﷺ"),  // SAW honorific ligature
            KeyData("ھ"),
            KeyData("ژ"),
            KeyData("چھے"),
            KeyData("چ"),
        ],
        // Row 2
        [
            KeyData("ِ"),   // kasra
            KeyData("ٰ"),   // superscript alef
            KeyData("ے"),
            KeyData("پ"),
            KeyData("ﷻ"),  // TA honorific ligature
            KeyData("ؓ"),   // radi allahu anhu
            KeyData("ـ"),   // tatweel
            KeyData("،"),   // Arabic comma
            KeyData("ں"),
            KeyData("گ"),
        ],
        // Row 3
        [
            KeyData("⇧", type: .shift, width: .wide),
            KeyData("ْ"),   // sukun
            KeyData("ٖ"),   // subscript alef
            KeyData("ۚ"),   // small high dotless head of khah
            KeyData("ڑ"),
            KeyData("ؒ"),   // radi allahu anhu (f)
            KeyData("ٹ"),
            KeyData("ڈ"),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4
        [
            KeyData("١٢٣", type: .numeric, width: .fixed(80)),
            KeyData(" ", type: .space, width: .flexible),
            KeyData("۞"),   // place of sajda symbol
            KeyData("↵", type: .enter, width: .fixed(80)),
        ],
    ])

    // ------------------------------------------------------------------ numeric

    static let numericLayer = KeyboardLayer(id: "numeric", rows: [
        // Row 1 — digits with Eastern-Arabic alternates
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
        // Row 3 — more symbols + Arabic literary marks
        [
            KeyData("@"),
            KeyData("("),
            KeyData(")"),
            KeyData("؏"),   // misra
            KeyData("ؔ"),   // takhallus
            KeyData("؃"),   // safha
            KeyData("؂", alternates: ["؎"]),  // footnote
            KeyData("؁", alternates: ["؄"]),  // year / samvat
            KeyData("؀", alternates: ["۝", "۩"]), // number sign / verse / sajda
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
