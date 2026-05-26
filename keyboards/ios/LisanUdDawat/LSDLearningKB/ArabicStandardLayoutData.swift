import Foundation

// iOS / macOS Arabic keyboard layout.
// Key positions match the Apple Arabic keyboard; double-tap secondaries and
// long-press alternates are identical to the LSD layout.

enum ArabicStandardLayoutData {

    static var defaultLayer: KeyboardLayer {
        let farsiYeh = KeyboardSettings.urduYehStyle == .farsiYeh
        let yeh      = farsiYeh ? "ی" : "ي"
        let yehAlt   = farsiYeh ? "ي" : "ی"
        let arabicHaa = KeyboardSettings.haaStyle == .arabic
        let haa       = arabicHaa ? "ه" : "ہ"
        let haaAlt    = arabicHaa ? "ہ" : "ه"
        let arabicKaaf = KeyboardSettings.kaafStyle == .arabic
        let kaaf       = arabicKaaf ? "ك" : "ک"
        let kaafAlt    = arabicKaaf ? "ک" : "ك"
        let arabicTaa = KeyboardSettings.taaMarbuta == .arabic
        let taa        = arabicTaa ? "ة" : "ۃ"
        let taaAlt     = arabicTaa ? "ۃ" : "ة"
        return KeyboardLayer(id: "arabic", rows: [
        // Row 1 — 11 keys
        [
            KeyData("ض", secondary: "ٹ"),
            KeyData("ص"),
            KeyData("ث", secondary: "پ"),
            KeyData("ق"),
            KeyData("ف"),
            KeyData("غ"),
            KeyData("ع"),
            KeyData(haa, secondary: "ھ",  alternates: [haaAlt, "ـہـ", "ـہ", "ۂ"]),
            KeyData("خ"),
            KeyData("ح", secondary: "چ"),
            KeyData("ج", secondary: "چھے"),
        ],
        // Row 2 — 10 keys (Mac/iOS Arabic omits ط from the main row)
        [
            KeyData("ش"),
            KeyData("س", secondary: "ے"),
            KeyData(yeh, secondary: "ئ",  alternates: [yehAlt, "ے"]),
            KeyData("ب"),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ", "لاٰ"]),
            KeyData("ا", secondary: "اٰ", alternates: ["أ", "آ", "إ"]),
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData(kaaf, secondary: "گ", alternates: [kaafAlt]),
            KeyData(taa, secondary: taaAlt),
        ],
        // Row 3 — 11 alpha + backspace
        [
            KeyData("ء"),
            KeyData("ظ", secondary: "ہ"),
            KeyData("ط", secondary: "ں"),
            KeyData("ذ"),
            KeyData("د", secondary: "ڈ",  alternates: ["ڈ"]),
            KeyData("ز", alternates: ["ژ"]),
            KeyData("ر", secondary: "ڑ",  alternates: ["ڑ"]),
            KeyData("ؤ", alternates: ["ۚ", "ۨ"]),
            KeyData("و", alternates: ["ؤ"]),
            KeyData("ى"),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4
        [
            KeyData("١٢٣",  type: .numeric,   width: .fixed(44)),
            KeyData("AaBb", type: .latin,     width: .fixed(44), longPressType: .globe),
            KeyData(" ",    alternates: ["\u{00A0}", "\u{200C}", "\u{0640}"],
                            type: .space,     width: .flexible),
            KeyData("تشكيل", type: .diacritic, width: .fixed(52)),
            KeyData("↵",    type: .enter,     width: .fixed(52)),
        ],
        ])
    }
}
