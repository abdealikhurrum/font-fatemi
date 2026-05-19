import Foundation

// CRULP Urdu Phonetic keyboard layout.
// Letters are placed on phonetically equivalent QWERTY positions.
// Double-tap secondaries cover retroflex / aspirated / nasal variants.
//
// Row 1  Q W  E  R  T  Y  U  I  O  P
//        ق و  ع  ر  ت  ے  ء  ح  ی  پ
//
// Row 2  A S  D  F  G  H  J  K  L
//        ا س  د  ف  گ  ہ  ج  ک  ل
//
// Row 3  Z X  C  V  B  N  M
//        ز ش  چ  ط  ب  ن  م

enum CRULPUrduLayoutData {

    static let defaultLayer = KeyboardLayer(id: "crulp", rows: [
        // Row 1 — 10 keys (QWERTYUIOP)
        [
            KeyData("ق"),
            KeyData("و", alternates: ["ؤ"]),
            KeyData("ع", secondary: "غ"),                          // عع → غ
            KeyData("ر", secondary: "ڑ"),                          // رر → ڑ
            KeyData("ت", secondary: "ٹ"),                          // تت → ٹ
            KeyData("ے", alternates: ["ئ", "ى"]),
            KeyData("ء"),
            KeyData("ح", secondary: "خ"),                          // حح → خ
            KeyData("ی", alternates: ["ئ", "ى"]),
            KeyData("پ"),
        ],
        // Row 2 — 9 keys (ASDFGHJKL)
        [
            KeyData("ا", alternates: ["آ", "أ", "إ", "اٰ"]),
            KeyData("س", alternates: ["ص", "ث"]),
            KeyData("د", secondary: "ڈ"),                          // دد → ڈ
            KeyData("ف"),
            KeyData("گ"),
            KeyData("ہ", secondary: "ھ",  alternates: ["ۃ"]),      // ہہ → ھ
            KeyData("ج", alternates: ["چ"]),
            KeyData("ک", alternates: ["ق"]),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ"]),
        ],
        // Row 3 — 7 alpha + backspace (ZXCVBNM)
        [
            KeyData("ز", secondary: "ذ", alternates: ["ژ"]),       // زز → ذ
            KeyData("ش", secondary: "ض", alternates: ["ص", "ث"]),  // شش → ض
            KeyData("چ"),
            KeyData("ط", alternates: ["ظ"]),
            KeyData("ب"),
            KeyData("ن", secondary: "ں"),                          // نن → ں
            KeyData("م"),
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
