import Foundation

// iOS / macOS Arabic keyboard layout.
// Key positions match the Apple Arabic keyboard; double-tap secondaries and
// long-press alternates are identical to the LSD layout.

enum ArabicStandardLayoutData {

    static let defaultLayer = KeyboardLayer(id: "arabic", rows: [
        // Row 1 — 11 keys
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
        // Row 2 — 10 keys (Mac/iOS Arabic omits ط from the main row)
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
        ],
        // Row 3 — 11 alpha + backspace
        [
            KeyData("ئ"),
            KeyData("ء"),
            KeyData("ؤ", alternates: ["ۚ", "ۨ"]),
            KeyData("ر", secondary: "ڑ",  alternates: ["ڑ"]),
            KeyData("ى"),
            KeyData("ة", secondary: "ۃ"),
            KeyData("و"),
            KeyData("ز", alternates: ["ژ"]),
            KeyData("ذ"),
            KeyData("د", secondary: "ڈ",  alternates: ["ڈ"]),
            KeyData("ظ", secondary: "ہ"),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4
        [
            KeyData("١٢٣", type: .numeric,  width: .fixed(44)),
            KeyData(" ",   alternates: ["\u{200D}", "\u{200C}", "\u{0640}"],
                           type: .space,    width: .flexible),
            KeyData("َ",   type: .diacritic, width: .fixed(36)),
            KeyData("↵",   type: .enter,    width: .fixed(52)),
        ],
    ])
}
