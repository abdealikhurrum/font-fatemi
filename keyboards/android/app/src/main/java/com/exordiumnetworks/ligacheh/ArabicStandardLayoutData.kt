package com.exordiumnetworks.ligacheh

import android.content.Context

// iOS / macOS Arabic keyboard layout.
// Key positions match the Apple Arabic keyboard; double-tap secondaries and
// long-press alternates are identical to the LSD layout.
object ArabicStandardLayoutData {

    fun defaultLayer(ctx: Context): KeyboardLayer {
        val yeh        = if (KeyboardSettings.getYehStyle(ctx) == KeyboardSettings.YehStyle.FARSI_YEH) "ی" else "ي"
        val yehAlt     = if (KeyboardSettings.getYehStyle(ctx) == KeyboardSettings.YehStyle.FARSI_YEH) "ي" else "ی"
        val arabicHaa  = KeyboardSettings.getHaaStyle(ctx) == KeyboardSettings.HaaStyle.ARABIC_HAA
        val haa        = if (arabicHaa) "ه" else "ہ"
        val haaAlt     = if (arabicHaa) "ہ" else "ه"
        val arabicKaaf = KeyboardSettings.getKaafStyle(ctx) == KeyboardSettings.KaafStyle.ARABIC_KAAF
        val kaaf       = if (arabicKaaf) "ك" else "ک"
        val kaafAlt    = if (arabicKaaf) "ک" else "ك"
        val arabicTaa  = KeyboardSettings.getTaaMarbuta(ctx) == KeyboardSettings.TaaMarbuta.ARABIC_TAA
        val taa        = if (arabicTaa) "ة" else "ۃ"
        val taaAlt     = if (arabicTaa) "ۃ" else "ة"
        return KeyboardLayer("arabic", listOf(
            // Row 1 — 11 keys
            listOf(
                KeyData("ض", secondary = "ٹ"),
                KeyData("ص"),
                KeyData("ث", secondary = "پ"),
                KeyData("ق"),
                KeyData("ف"),
                KeyData("غ"),
                KeyData("ع"),
                KeyData(haa, secondary = "ھ", alternates = listOf(haaAlt, "ـہـ", "ـہ", "ۂ")),
                KeyData("خ"),
                KeyData("ح", secondary = "چ"),
                KeyData("ج", secondary = "چھے"),
            ),
            // Row 2 — 11 keys
            listOf(
                KeyData("ش"),
                KeyData("س", secondary = "ے"),
                KeyData(yeh, secondary = "ئ",  alternates = listOf(yehAlt, "ے")),
                KeyData("ب"),
                KeyData("ل", alternates = listOf("لا", "لأ", "لإ", "لآ", "لاٰ")),
                KeyData("ا", secondary = "اٰ", alternates = listOf("أ", "آ", "إ")),
                KeyData("ت"),
                KeyData("ن"),
                KeyData("م"),
                KeyData(kaaf, secondary = "گ", alternates = listOf(kaafAlt)),
                KeyData(taa, secondary = taaAlt),
            ),
            // Row 3 — 10 alpha + backspace
            listOf(
                KeyData("ء"),
                KeyData("ظ", secondary = "ہ"),
                KeyData("ط", secondary = "ں"),
                KeyData("ذ"),
                KeyData("د", secondary = "ڈ",  alternates = listOf("ڈ")),
                KeyData("ز", alternates = listOf("ژ")),
                KeyData("ر", secondary = "ڑ",  alternates = listOf("ڑ")),
                KeyData("ؤ", alternates = listOf("ۚ", "ۨ")),
                KeyData("و", alternates = listOf("ؤ")),
                KeyData("ى"),
                KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.Wide),
            ),
            // Row 4
            listOf(
                KeyData("١٢٣",   type = KeyType.NUMERIC,   width = KeyWidth.Fixed(44f)),
                KeyData("AaBb",  type = KeyType.LATIN,     width = KeyWidth.Fixed(44f),
                             longPressType = KeyType.GLOBE),
                KeyData(" ",      type = KeyType.SPACE,     width = KeyWidth.Flexible,
                                  alternates = listOf(" ", "‌", "ـ")),
                KeyData("تشكيل", type = KeyType.DIACRITIC, width = KeyWidth.Fixed(52f)),
                KeyData("↵",      type = KeyType.ENTER,     width = KeyWidth.Fixed(52f)),
            ),
        ))
    }
}
