import Foundation

// Standard Arabic keyboard layout matching iOS/macOS Arabic keyboard.
// No Urdu-specific secondary characters; long-press alternates are Arabic-only.

enum ArabicStandardLayoutData {

    static let defaultLayer = KeyboardLayer(id: "arabic", rows: [
        // Row 1 — 11 keys
        [
            KeyData("ض"),
            KeyData("ص"),
            KeyData("ث"),
            KeyData("ق"),
            KeyData("ف"),
            KeyData("غ"),
            KeyData("ع"),
            KeyData("ه", alternates: ["ة", "ۃ"]),
            KeyData("خ"),
            KeyData("ح"),
            KeyData("ج"),
        ],
        // Row 2 — 11 keys
        [
            KeyData("ش"),
            KeyData("س"),
            KeyData("ي", alternates: ["ى", "ئ"]),
            KeyData("ب"),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ"]),
            KeyData("ا", alternates: ["أ", "آ", "إ"]),
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData("ك"),
            KeyData("ط"),
        ],
        // Row 3 — 11 alpha + backspace
        [
            KeyData("ئ"),
            KeyData("ء"),
            KeyData("ؤ"),
            KeyData("ر"),
            KeyData("ى"),
            KeyData("ة"),
            KeyData("و", alternates: ["ؤ"]),
            KeyData("ز", alternates: ["ژ"]),
            KeyData("ذ"),
            KeyData("د"),
            KeyData("ظ"),
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4
        [
            KeyData("١٢٣", type: .numeric,  width: .fixed(44)),
            KeyData(" ",   type: .space,    width: .flexible),
            KeyData("َ",   type: .diacritic, width: .fixed(36)),
            KeyData("↵",   type: .enter,    width: .fixed(52)),
        ],
    ])
}
