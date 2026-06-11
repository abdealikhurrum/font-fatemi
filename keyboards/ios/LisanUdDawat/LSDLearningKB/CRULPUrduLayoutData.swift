import Foundation

// Phonetic-based keyboard layout (derived from the CRULP Urdu phonetic layout).
// Letters are placed on phonetically equivalent QWERTY positions.
//
// Three tiers of access:
//   - tap            primary letter
//   - double-tap     CRULP double-press secondaries (عع→غ رر→ڑ تت→ٹ حح→خ
//                    دد→ڈ هه→ھ زز→ذ شش→ض نن→ں + اا→اٰ)
//   - shift (⇧)      hamza carriers, emphatics, taa marbuta forms, and the
//                    style counterparts (ه↔ہ ك↔ک ي↔ی)
//
// Row 1  Q W  E  R  T  Y  U  I  O  P
//        ق و  ع  ر  ت  ے  ء  ح  ی  پ
//  ⇧     ق ؤ  غ  ڑ  ة  ى  ئ  خ  ی٭ ژ
//
// Row 2  A S  D  F  G  H  J  K  L
//        ا س  د  ف  گ  ہ  ج  ک  ل
//  ⇧     آ ص  ڈ  ف  گ  ہ٭ چھے ک٭ لا
//
// Row 3  ⇧ Z  X  C  V  B  N  M  ⌫
//          ز  ش  چ  ط  ب  ن  م
//  ⇧       ذ  ض  ث  ظ  ب  ں  ۃ
//
// ٭ = the other style variant per current settings (yeh/haa/kaaf).

enum CRULPUrduLayoutData {

    // Computed so all character styles reflect current settings without restarting.
    static var defaultLayer: KeyboardLayer {
        let yeh        = KeyboardSettings.urduYehStyle == .farsiYeh ? "ی" : "ي"
        let yehAlt     = KeyboardSettings.urduYehStyle == .farsiYeh ? "ي" : "ی"
        let arabicHaa  = KeyboardSettings.haaStyle == .arabic
        let haa        = arabicHaa ? "ه" : "ہ"
        let haaAlt     = arabicHaa ? "ہ" : "ه"
        let arabicKaaf = KeyboardSettings.kaafStyle == .arabic
        let kaaf       = arabicKaaf ? "ك" : "ک"
        let kaafAlt    = arabicKaaf ? "ک" : "ك"
        let taa        = KeyboardSettings.taaMarbuta == .arabic ? "ة" : "ۃ"
        return KeyboardLayer(id: "crulp", rows: [
        // Row 1 — 10 keys (QWERTYUIOP)
        [
            KeyData("ق"),
            KeyData("و", alternates: ["ؤ"]),
            KeyData("ع", secondary: "غ"),                                    // عع → غ
            KeyData("ر", secondary: "ڑ"),                                    // رر → ڑ
            KeyData("ت", secondary: "ٹ"),                                    // تت → ٹ
            KeyData("ے", alternates: ["ئ", "ى"]),
            KeyData("ء"),
            KeyData("ح", secondary: "خ"),                                    // حح → خ
            KeyData(yeh, alternates: ["ئ", "ى", yehAlt]),                    // alternate = other yeh
            KeyData("پ"),
        ],
        // Row 2 — 9 keys (ASDFGHJKL)
        [
            KeyData("ا", secondary: "اٰ", alternates: ["آ", "أ", "إ"]),      // اا → اٰ
            KeyData("س", alternates: ["ص", "ث"]),
            KeyData("د", secondary: "ڈ"),                               // دد → ڈ
            KeyData("ف"),
            KeyData("گ"),
            KeyData(haa, secondary: "ھ", alternates: [haaAlt, taa]),    // ہہ → ھ; taa marbuta accessible here
            KeyData("ج", alternates: ["چ"]),
            KeyData(kaaf, alternates: [kaafAlt, "ق"]),
            KeyData("ل", alternates: ["لا", "لأ", "لإ", "لآ"]),
        ],
        // Row 3 — shift + 7 alpha + backspace (ZXCVBNM)
        [
            KeyData("⇧", type: .shift, width: .wide),
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
            KeyData(" ",   alternates: ["\u{00A0}", "\u{200C}", "\u{0640}"],
                           type: .space,    width: .flexible),
            KeyData("تشكيل", type: .diacritic, width: .fixed(52)),
            KeyData("↵",   type: .enter,    width: .fixed(52)),
        ],
        ])
    }

    // Shift layer — same grid, one-shot like the Latin shift. Carries the
    // characters that have no comfortable double-press slot: hamza carriers
    // (ؤ ئ ى), emphatics (ص ض ث ظ ذ), taa marbuta forms (ة ۃ), Persian ژ,
    // the lam-alef ligature, and the style counterparts (ه↔ہ ك↔ک ي↔ی).
    static var shiftLayer: KeyboardLayer {
        let yehAlt     = KeyboardSettings.urduYehStyle == .farsiYeh ? "ي" : "ی"
        let arabicHaa  = KeyboardSettings.haaStyle == .arabic
        let haaAlt     = arabicHaa ? "ہ" : "ه"
        let arabicKaaf = KeyboardSettings.kaafStyle == .arabic
        let kaafAlt    = arabicKaaf ? "ک" : "ك"
        return KeyboardLayer(id: "crulp_shift", rows: [
        // Row 1
        [
            KeyData("ق"),
            KeyData("ؤ"),
            KeyData("غ"),
            KeyData("ڑ"),
            KeyData("ة"),                       // taa marbuta (ت position)
            KeyData("ى"),                       // alef maqsura (ے position)
            KeyData("ئ"),                       // yeh hamza (ء position)
            KeyData("خ"),
            KeyData(yehAlt),                    // the other yeh style
            KeyData("ژ"),                       // Persian pair with پ
        ],
        // Row 2
        [
            KeyData("آ", alternates: ["أ", "إ", "اٰ"]),
            KeyData("ص"),
            KeyData("ڈ"),
            KeyData("ف"),
            KeyData("گ"),
            KeyData(haaAlt, alternates: ["ۂ", "ـہ"]),   // the other haa style
            KeyData("چھے"),                     // LSD jeem ligature (ج position)
            KeyData(kaafAlt),                   // the other kaaf style
            KeyData("لا", alternates: ["لأ", "لإ", "لآ"]),
        ],
        // Row 3
        [
            KeyData("⬆", type: .shift, width: .wide),
            KeyData("ذ"),
            KeyData("ض"),
            KeyData("ث"),                       // C position — c↔s
            KeyData("ظ"),
            KeyData("ب"),
            KeyData("ں"),
            KeyData("ۃ"),                       // Urdu taa marbuta (م position)
            KeyData("⌫", type: .backspace, width: .wide),
        ],
        // Row 4
        [
            KeyData("١٢٣", type: .numeric,  width: .fixed(44)),
            KeyData(" ",   alternates: ["\u{00A0}", "\u{200C}", "\u{0640}"],
                           type: .space,    width: .flexible),
            KeyData("تشكيل", type: .diacritic, width: .fixed(52)),
            KeyData("↵",   type: .enter,    width: .fixed(52)),
        ],
        ])
    }
}
