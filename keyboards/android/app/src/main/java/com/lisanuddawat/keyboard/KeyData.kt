package com.lisanuddawat.keyboard

// Ported from iOS LSDLearningKB/KeyData.swift
// KeyWidth.Fixed values are in dp.

enum class KeyType {
    CHARACTER, BACKSPACE, SPACE, ENTER,
    NUMERIC, ABC, GLOBE, EMOJI, DIACRITIC,
    CURSOR_LEFT, CURSOR_RIGHT
}

sealed class KeyWidth {
    object Standard  : KeyWidth()
    object Wide      : KeyWidth()
    object ExtraWide : KeyWidth()
    object Flexible  : KeyWidth()
    data class Fixed(val dp: Float) : KeyWidth()
}

data class KeyData(
    val primary: String,
    val secondary: String = "",
    val alternates: List<String> = emptyList(),
    val type: KeyType = KeyType.CHARACTER,
    val width: KeyWidth = KeyWidth.Standard
) {
    companion object {
        // Double-press secondaries — identical to iOS and macOS.
        // Official LSD rules (lsd.kmn): سس→ے  ضض→ٹ  طط→ں  ظظ→ہ  حح→چ  ثث→پ  كك→گ
        // Extended:                      اا→اٰ  هه→ھ  يي→ئ  رر→ڑ  دد→ڈ  ةة→ۃ  جج→چھے
        private val secondaryMap = mapOf(
            "ض" to "ٹ",  "ث" to "پ",  "ه" to "ھ",  "ح" to "چ",
            "ج" to "چھے","س" to "ے",  "ي" to "ئ",  "ا" to "اٰ",
            "ك" to "گ",  "ط" to "ں",  "ر" to "ڑ",  "ة" to "ۃ",
            "د" to "ڈ",  "ظ" to "ہ"
        )

        fun secondaryFor(char: String): String? =
            secondaryMap[char]?.takeIf { it.isNotEmpty() }
    }
}

data class KeyboardLayer(val id: String, val rows: List<List<KeyData>>)

object KeyboardLayoutData {

    val defaultLayer = KeyboardLayer("default", listOf(
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
            KeyData("ط", secondary = "ں"),
        ),
        listOf(
            KeyData("ئ"),
            KeyData("ء"),
            KeyData("ؤ", alternates = listOf("ۚ", "ۨ")),
            KeyData("ر", secondary = "ڑ",  alternates = listOf("ڑ")),
            KeyData("ى"),
            KeyData("ة", secondary = "ۃ"),
            KeyData("و"),
            KeyData("ز", alternates = listOf("ژ", "ذ")),
            KeyData(primary= "ذ"),
            KeyData("د", secondary = "ڈ",  alternates = listOf("ڈ")),
            KeyData("ظ", secondary = "ہ"),
            KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.Wide),
        ),
        listOf(
            KeyData("١٢٣", type = KeyType.NUMERIC,   width = KeyWidth.Fixed(44f)),
            KeyData("🌐",   type = KeyType.GLOBE,     width = KeyWidth.Fixed(44f)),
            KeyData(" ",    type = KeyType.SPACE,     width = KeyWidth.Flexible,
                            alternates = listOf(" ", "‌", "ـ")),
            KeyData("تشكيل", type = KeyType.DIACRITIC, width = KeyWidth.Fixed(52f)),
            KeyData("↵",    type = KeyType.ENTER,     width = KeyWidth.Fixed(52f)),
        ),
    ))

    val numericLayer = KeyboardLayer("numeric", listOf(
        listOf(
            KeyData("١", alternates = listOf("1", "૧")),
            KeyData("٢", alternates = listOf("2", "૨")),
            KeyData("٣", alternates = listOf("3", "૩")),
            KeyData("٤", alternates = listOf("4", "૪")),
            KeyData("٥", alternates = listOf("5", "૫")),
            KeyData("٦", alternates = listOf("6", "૬")),
            KeyData("٧", alternates = listOf("7", "૭")),
            KeyData("٨", alternates = listOf("8", "૮")),
            KeyData("٩", alternates = listOf("9", "૯")),
            KeyData("٠", alternates = listOf("0", "૰")),
        ),
        listOf(
            KeyData(".",  alternates = listOf("۔")),
            KeyData("،",  alternates = listOf(",")),
            KeyData("؟",  alternates = listOf("?")),
            KeyData("!"),
            KeyData("؛",  alternates = listOf(";")),
            KeyData(":"),
            KeyData("\"", alternates = listOf("«", "»")),
            KeyData("'",  alternates = listOf("`")),
            KeyData("(",  alternates = listOf("[", "{")),
            KeyData(")",  alternates = listOf("]", "}")),
        ),
        listOf(
            KeyData("$",  alternates = listOf("₨", "¥", "€", "؋")),
            KeyData("#"),
            KeyData("%",  alternates = listOf("٪")),
            KeyData("^"),
            KeyData("+",  alternates = listOf("×")),
            KeyData("="),
            KeyData("*",  alternates = listOf("٭")),
            KeyData("-",  alternates = listOf("÷", "_")),
            KeyData("@"),
            KeyData("⌫",  type = KeyType.BACKSPACE, width = KeyWidth.Wide),
        ),
        listOf(
            KeyData("ا ب ج", type = KeyType.ABC,   width = KeyWidth.Fixed(80f)),
            KeyData("🌐",     type = KeyType.GLOBE,  width = KeyWidth.Fixed(44f)),
            KeyData(" ",      type = KeyType.SPACE,  width = KeyWidth.Flexible,
                              alternates = listOf(" ", "‌", "ـ")),
            KeyData("↵",      type = KeyType.ENTER,  width = KeyWidth.Fixed(80f)),
        ),
    ))

    val diacriticLayer = KeyboardLayer("diacritic", listOf(
        listOf(
            KeyData("َ"), KeyData("ِ"), KeyData("ُ"), KeyData("ْ"), KeyData("ّ"),
            KeyData("ً"), KeyData("ٍ"), KeyData("ٌ"), KeyData("ٰ"),
        ),
        listOf(
            KeyData("ﷺ"), KeyData("ﷻ"), KeyData("ؓ"), KeyData("ؒ"), KeyData("ؑ"),
            KeyData("ؐ"), KeyData("ؔ"), KeyData("ؕ"), KeyData("؈"), KeyData("؃"),
        ),
        listOf(
            KeyData("ٓ"), KeyData("ٔ"), KeyData("ٕ"), KeyData("؏"),
            KeyData("؂", alternates = listOf("؎")),
            KeyData("؁", alternates = listOf("؄")),
            KeyData("؀", alternates = listOf("۝", "۩")),
            KeyData("ۚ"), KeyData("ۨ"),
            KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.Wide),
        ),
        listOf(
            KeyData("🌐",     type = KeyType.GLOBE,         width = KeyWidth.Fixed(44f)),
            KeyData("←",      type = KeyType.CURSOR_RIGHT,  width = KeyWidth.Fixed(44f)),
            KeyData(" ",      type = KeyType.SPACE,         width = KeyWidth.Flexible,
                              alternates = listOf(" ", "‌", "ـ")),
            KeyData("→",      type = KeyType.CURSOR_LEFT,   width = KeyWidth.Fixed(44f)),
            KeyData("ا ب ج", type = KeyType.ABC,           width = KeyWidth.Fixed(52f)),
            KeyData("↵",      type = KeyType.ENTER,         width = KeyWidth.Fixed(52f)),
        ),
    ))
}
