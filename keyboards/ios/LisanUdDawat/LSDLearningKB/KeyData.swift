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
    case emoji      // advance to emoji keyboard
    case diacritic    // switch to diacritics / eraab layer
    case cursorLeft   // move cursor one position left
    case cursorRight  // move cursor one position right
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
//     اا→اٰ  هه→ھ  يي→ئ  رر→ڑ  دد→ڈ  ةة→ۃ
//
// Long-press alternates are ordered by frequency so the first item is
// quickest to reach (slide right / nearest target in the popup).

enum KeyboardLayoutData {

    // ------------------------------------------------------------------ default

    static let defaultLayer = KeyboardLayer(id: "default", rows: [
        // Row 1 — 11 keys  (matches PC Arabic row 1: Q–[)
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
        // Row 2 — 11 keys  (matches PC Arabic row 2: A–' ; ط added at end)
        [
            KeyData("ش"),
            KeyData("س", secondary: "ے"),                                       // سس → ے
            KeyData("ي", secondary: "ئ",  alternates: ["ے"]),                   // يي → ئ
            KeyData("ب"),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ", "لاٰ"]),
            KeyData("ا", secondary: "اٰ", alternates: ["أ", "آ", "إ"]),        // اا → اٰ
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData("ك", secondary: "گ",  alternates: ["گ"]),                   // كك → گ
            KeyData("ط", secondary: "ں"),                                       // طط → ں  (PC: ' key)
        ],
        // Row 3 — 10 alpha + backspace  (matches PC Arabic row 3: Z–/)
        [
            KeyData("ئ"),
            KeyData("ء"),
            KeyData("ؤ", alternates: ["ۚ", "ۨ"]),
            KeyData("ر", secondary: "ڑ",  alternates: ["ڑ"]),                   // رر → ڑ
            KeyData("ى"),
            KeyData("ة", secondary: "ۃ"),                                       // ةة → ۃ
            KeyData("و"),
            KeyData("ز", alternates: ["ژ", "ذ"]),
            KeyData("د", secondary: "ڈ",  alternates: ["ڈ"]),                   // دد → ڈ
            KeyData("ظ", secondary: "ہ"),                                       // ظظ → ہ
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4 — 4 keys; punctuation lives in the ١٢٣ layer
        [
            KeyData("١٢٣", type: .numeric,  width: .fixed(44)),
            KeyData(" ",   type: .space,    width: .flexible),
            KeyData("َ",   type: .diacritic, width: .fixed(44)),   // opens diacritic layer
            KeyData("↵",   type: .enter,    width: .fixed(52)),
        ],
    ])

    // ------------------------------------------------------------------ numeric

    static let numericLayer = KeyboardLayer(id: "numeric", rows: [
        // Row 1 — Eastern Arabic digits (primary); Western Arabic as alternates
        [
            KeyData("١", alternates: ["1", "૧"]),
            KeyData("٢", alternates: ["2", "૨"]),
            KeyData("٣", alternates: ["3", "૩"]),
            KeyData("٤", alternates: ["4", "૪"]),
            KeyData("٥", alternates: ["5", "૫"]),
            KeyData("٦", alternates: ["6", "૬"]),
            KeyData("٧", alternates: ["7", "૭"]),
            KeyData("٨", alternates: ["8", "૮"]),
            KeyData("٩", alternates: ["9", "૯"]),
            KeyData("٠", alternates: ["0", "૰"]),
        ],
        // Row 2 — punctuation
        [
            KeyData(".",  alternates: ["۔"]),
            KeyData("،",  alternates: [","]),
            KeyData("؟",  alternates: ["?"]),
            KeyData("!"),
            KeyData("؛",  alternates: [";"]),
            KeyData(":",  alternates: []),
            KeyData("\"", alternates: ["«", "»"]),
            KeyData("'",  alternates: ["`"]),
            KeyData("(",  alternates: ["[", "{"]),
            KeyData(")",  alternates: ["]", "}"]),
        ],
        // Row 3 — math / symbols
        [
            KeyData("$",  alternates: ["₨", "¥", "€", "؋"]),
            KeyData("#"),
            KeyData("%",  alternates: ["٪"]),
            KeyData("^"),
            KeyData("+",  alternates: ["×"]),
            KeyData("="),
            KeyData("*",  alternates: ["٭"]),
            KeyData("-",  alternates: ["÷", "_"]),
            KeyData("@"),
            KeyData("⌫",  type: .backspace, width: .wide),
        ],
        // Row 4
        [
            KeyData("ا ب ج", type: .abc,   width: .fixed(80)),
            KeyData(" ",     type: .space,  width: .flexible),
            KeyData("↵",     type: .enter,  width: .fixed(80)),
        ],
    ])

    // ------------------------------------------------------------------ diacritic

    static let diacriticLayer = KeyboardLayer(id: "diacritic", rows: [
        // Row 1 — core harakat (all are combining marks; KeyButton prepends tatweel)
        [
            KeyData("َ"),   // fatha
            KeyData("ِ"),   // kasra
            KeyData("ُ"),   // damma
            KeyData("ْ"),   // sukun
            KeyData("ّ"),   // shadda
            KeyData("ً"),   // tanwin fath
            KeyData("ٍ"),   // tanwin kasr
            KeyData("ٌ"),   // tanwin damm
            KeyData("ٰ"),   // superscript alef (kharo zabar)
        ],
        // Row 2 — honorifics
        [
            KeyData("ﷺ"),
            KeyData("ﷻ"),
            KeyData("ؓ"),
            KeyData("ؒ"),
            KeyData("ؑ"),
            KeyData("ؐ"),
            KeyData("ؔ"),   // takhallus
            KeyData("ؕ"),
            KeyData("؈"),
            KeyData("؃"),   // safha
        ],
        // Row 3 — extended marks + literary
        [
            KeyData("ٓ"),               // maddah
            KeyData("ٔ"),               // hamza above
            KeyData("ٕ"),               // hamza below
            KeyData("؏"),               // misra
            KeyData("؂", alternates: ["؎"]),
            KeyData("؁", alternates: ["؄"]),
            KeyData("؀", alternates: ["۝", "۩"]),
            KeyData("ۚ"),
            KeyData("ۨ"),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4 — cursor keys for precise diacritic placement
        [
            KeyData("ا ب ج", type: .abc,         width: .fixed(72)),
            KeyData("←",     type: .cursorLeft,  width: .fixed(44)),
            KeyData(" ",     type: .space,       width: .flexible),
            KeyData("→",     type: .cursorRight, width: .fixed(44)),
            KeyData("↵",     type: .enter,       width: .fixed(52)),
        ],
    ])
}
