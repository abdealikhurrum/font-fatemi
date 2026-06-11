package com.exordiumnetworks.ligacheh

import android.content.Context

// Phonetic-based keyboard layout (derived from the CRULP Urdu phonetic layout).
// Letters are placed on phonetically equivalent QWERTY positions.
// Mirrors iOS LSDLearningKB/CRULPUrduLayoutData.swift.
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
object CRULPUrduLayoutData {

    // Computed so all character styles reflect current settings without restarting.
    fun defaultLayer(ctx: Context): KeyboardLayer {
        val yeh        = if (KeyboardSettings.getYehStyle(ctx) == KeyboardSettings.YehStyle.FARSI_YEH) "ی" else "ي"
        val yehAlt     = if (KeyboardSettings.getYehStyle(ctx) == KeyboardSettings.YehStyle.FARSI_YEH) "ي" else "ی"
        val arabicHaa  = KeyboardSettings.getHaaStyle(ctx) == KeyboardSettings.HaaStyle.ARABIC_HAA
        val haa        = if (arabicHaa) "ه" else "ہ"
        val haaAlt     = if (arabicHaa) "ہ" else "ه"
        val arabicKaaf = KeyboardSettings.getKaafStyle(ctx) == KeyboardSettings.KaafStyle.ARABIC_KAAF
        val kaaf       = if (arabicKaaf) "ك" else "ک"
        val kaafAlt    = if (arabicKaaf) "ک" else "ك"
        val taa        = if (KeyboardSettings.getTaaMarbuta(ctx) == KeyboardSettings.TaaMarbuta.ARABIC_TAA) "ة" else "ۃ"
        return KeyboardLayer("crulp", listOf(
            // Row 1 — 10 keys (QWERTYUIOP)
            listOf(
                KeyData("ق"),
                KeyData("و", alternates = listOf("ؤ")),
                KeyData("ع", secondary = "غ"),                                  // عع → غ
                KeyData("ر", secondary = "ڑ"),                                  // رر → ڑ
                KeyData("ت", secondary = "ٹ"),                                  // تت → ٹ
                KeyData("ے", alternates = listOf("ئ", "ى")),
                KeyData("ء"),
                KeyData("ح", secondary = "خ"),                                  // حح → خ
                KeyData(yeh, alternates = listOf("ئ", "ى", yehAlt)),            // alternate = other yeh
                KeyData("پ"),
            ),
            // Row 2 — 9 keys (ASDFGHJKL)
            listOf(
                KeyData("ا", secondary = "اٰ", alternates = listOf("آ", "أ", "إ")),  // اا → اٰ
                KeyData("س", alternates = listOf("ص", "ث")),
                KeyData("د", secondary = "ڈ"),                              // دد → ڈ
                KeyData("ف"),
                KeyData("گ"),
                KeyData(haa, secondary = "ھ", alternates = listOf(haaAlt, taa)),  // ہہ → ھ; taa marbuta accessible here
                KeyData("ج", alternates = listOf("چ")),
                KeyData(kaaf, alternates = listOf(kaafAlt, "ق")),
                KeyData("ل", alternates = listOf("لا", "لأ", "لإ", "لآ")),
            ),
            // Row 3 — shift + 7 alpha + backspace (ZXCVBNM)
            listOf(
                KeyData("⇧", type = KeyType.SHIFT, width = KeyWidth.Wide),
                KeyData("ز", secondary = "ذ", alternates = listOf("ژ")),        // زز → ذ
                KeyData("ش", secondary = "ض", alternates = listOf("ص", "ث")),   // شش → ض
                KeyData("چ"),
                KeyData("ط", alternates = listOf("ظ")),
                KeyData("ب"),
                KeyData("ن", secondary = "ں"),                                  // نن → ں
                KeyData("م"),
                KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.Wide),
            ),
            // Row 4
            row4(),
        ))
    }

    // Shift layer — same grid, one-shot like the Latin shift. Carries the
    // characters that have no comfortable double-press slot: hamza carriers
    // (ؤ ئ ى), emphatics (ص ض ث ظ ذ), taa marbuta forms (ة ۃ), Persian ژ,
    // the lam-alef ligature, and the style counterparts (ه↔ہ ك↔ک ي↔ی).
    fun shiftLayer(ctx: Context): KeyboardLayer {
        val yehAlt     = if (KeyboardSettings.getYehStyle(ctx) == KeyboardSettings.YehStyle.FARSI_YEH) "ي" else "ی"
        val arabicHaa  = KeyboardSettings.getHaaStyle(ctx) == KeyboardSettings.HaaStyle.ARABIC_HAA
        val haaAlt     = if (arabicHaa) "ہ" else "ه"
        val arabicKaaf = KeyboardSettings.getKaafStyle(ctx) == KeyboardSettings.KaafStyle.ARABIC_KAAF
        val kaafAlt    = if (arabicKaaf) "ک" else "ك"
        return KeyboardLayer("crulp_shift", listOf(
            // Row 1
            listOf(
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
            ),
            // Row 2
            listOf(
                KeyData("آ", alternates = listOf("أ", "إ", "اٰ")),
                KeyData("ص"),
                KeyData("ڈ"),
                KeyData("ف"),
                KeyData("گ"),
                KeyData(haaAlt, alternates = listOf("ۂ", "ـہ")),   // the other haa style
                KeyData("چھے"),                     // LSD jeem ligature (ج position)
                KeyData(kaafAlt),                   // the other kaaf style
                KeyData("لا", alternates = listOf("لأ", "لإ", "لآ")),
            ),
            // Row 3
            listOf(
                KeyData("⬆", type = KeyType.SHIFT, width = KeyWidth.Wide),
                KeyData("ذ"),
                KeyData("ض"),
                KeyData("ث"),                       // C position — c↔s
                KeyData("ظ"),
                KeyData("ب"),
                KeyData("ں"),
                KeyData("ۃ"),                       // Urdu taa marbuta (م position)
                KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.Wide),
            ),
            // Row 4
            row4(),
        ))
    }

    private fun row4() = listOf(
        KeyData("١٢٣",   type = KeyType.NUMERIC,   width = KeyWidth.Fixed(44f)),
        KeyData("AaBb",  type = KeyType.LATIN,     width = KeyWidth.Fixed(44f),
                     longPressType = KeyType.GLOBE),
        KeyData(" ",      type = KeyType.SPACE,     width = KeyWidth.Flexible,
                          alternates = listOf(" ", "‌", "ـ")),
        KeyData("تشكيل", type = KeyType.DIACRITIC, width = KeyWidth.Fixed(52f)),
        KeyData("↵",      type = KeyType.ENTER,     width = KeyWidth.Fixed(52f)),
    )
}
