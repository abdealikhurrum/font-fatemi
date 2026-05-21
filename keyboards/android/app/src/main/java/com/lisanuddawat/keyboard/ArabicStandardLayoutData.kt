package com.lisanuddawat.keyboard

// iOS / macOS Arabic keyboard layout.
// Key positions match the Apple Arabic keyboard; double-tap secondaries and
// long-press alternates are identical to the LSD layout.
object ArabicStandardLayoutData {

    val defaultLayer = KeyboardLayer("arabic", listOf(
        // Row 1 — 11 keys
        listOf(
            KeyData("ض", secondary = "ٹ"),
            KeyData("ص"),
            KeyData("ث", secondary = "پ"),
            KeyData("ق"),
            KeyData("ف"),
            KeyData("غ"),
            KeyData("ع"),
            KeyData("ه", secondary = "ھ",  alternates = listOf("ـہـ", "ـہ", "ۂ")),
            KeyData("خ"),
            KeyData("ح", secondary = "چ"),
            KeyData("ج", secondary = "چھے"),
        ),
        // Row 2 — 11 keys
        listOf(
            KeyData("ش"),
            KeyData("س", secondary = "ے"),
            KeyData("ي", secondary = "ئ",  alternates = listOf("ے")),
            KeyData("ب"),
            KeyData("ل", alternates = listOf("لا", "لأ", "لإ", "لآ", "لاٰ")),
            KeyData("ا", secondary = "اٰ", alternates = listOf("أ", "آ", "إ")),
            KeyData("ت"),
            KeyData("ن"),
            KeyData("م"),
            KeyData("ك", secondary = "گ",  alternates = listOf("گ")),
            KeyData("ة", secondary = "ۃ"),
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
            KeyData("١٢٣",    type = KeyType.NUMERIC,   width = KeyWidth.Fixed(44f)),
            KeyData("🌐",      type = KeyType.GLOBE,     width = KeyWidth.Fixed(44f)),
            KeyData(" ",       type = KeyType.SPACE,     width = KeyWidth.Flexible,
                               alternates = listOf(" ", "‌", "ـ")),
            KeyData("تشكيل",  type = KeyType.DIACRITIC, width = KeyWidth.Fixed(52f)),
            KeyData("↵",       type = KeyType.ENTER,     width = KeyWidth.Fixed(52f)),
        ),
    ))
}
