package com.lisanuddawat.keyboard

import android.content.Context

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
object CRULPUrduLayoutData {

    // Computed so the yeh character reflects the current setting without restarting.
    fun defaultLayer(ctx: Context): KeyboardLayer {
        val yeh    = if (KeyboardSettings.getUrduYehStyle(ctx) == KeyboardSettings.UrduYehStyle.FARSI_YEH) "ی" else "ي"
        val yehAlt = if (KeyboardSettings.getUrduYehStyle(ctx) == KeyboardSettings.UrduYehStyle.FARSI_YEH) "ي" else "ی"
        return KeyboardLayer("crulp", listOf(
            // Row 1 — 10 keys (QWERTYUIOP)
            listOf(
                KeyData("ق"),
                KeyData("و", alternates = listOf("ؤ")),
                KeyData("ع", secondary = "غ"),
                KeyData("ر", secondary = "ڑ"),
                KeyData("ت", secondary = "ٹ"),
                KeyData("ے", alternates = listOf("ئ", "ى")),
                KeyData("ء"),
                KeyData("ح", secondary = "خ"),
                KeyData(yeh, alternates = listOf("ئ", "ى", yehAlt)),
                KeyData("پ"),
            ),
            // Row 2 — 9 keys (ASDFGHJKL)
            listOf(
                KeyData("ا", alternates = listOf("آ", "أ", "إ", "اٰ")),
                KeyData("س", alternates = listOf("ص", "ث")),
                KeyData("د", secondary = "ڈ"),
                KeyData("ف"),
                KeyData("گ"),
                KeyData("ہ", secondary = "ھ", alternates = listOf("ۃ")),
                KeyData("ج", alternates = listOf("چ")),
                KeyData("ک", alternates = listOf("ق")),
                KeyData("ل", alternates = listOf("لا", "لأ", "لإ", "لآ")),
            ),
            // Row 3 — 7 alpha + backspace (ZXCVBNM)
            listOf(
                KeyData("ز", secondary = "ذ", alternates = listOf("ژ")),
                KeyData("ش", secondary = "ض", alternates = listOf("ص", "ث")),
                KeyData("چ"),
                KeyData("ط", alternates = listOf("ظ")),
                KeyData("ب"),
                KeyData("ن", secondary = "ں"),
                KeyData("م"),
                KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.Wide),
            ),
            // Row 4
            listOf(
                KeyData("١٢٣",   type = KeyType.NUMERIC,   width = KeyWidth.Fixed(44f)),
                KeyData("🌐",     type = KeyType.GLOBE,     width = KeyWidth.Fixed(44f)),
                KeyData(" ",      type = KeyType.SPACE,     width = KeyWidth.Flexible,
                                  alternates = listOf(" ", "‌", "ـ")),
                KeyData("تشكيل", type = KeyType.DIACRITIC, width = KeyWidth.Fixed(52f)),
                KeyData("↵",      type = KeyType.ENTER,     width = KeyWidth.Fixed(52f)),
            ),
        ))
    }
}
