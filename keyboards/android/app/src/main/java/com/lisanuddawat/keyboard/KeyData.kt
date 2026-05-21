package com.lisanuddawat.keyboard

enum class KeyType {
    CHARACTER, SHIFT, BACKSPACE, SPACE, ENTER, NUMERIC, ABC, GLOBE
}

enum class KeyWidthType {
    STANDARD, WIDE, EXTRA_WIDE, FLEXIBLE, FIXED
}

data class KeyWidth(
    val type: KeyWidthType,
    val fixedDp: Float = 0f
) {
    companion object {
        val STANDARD  = KeyWidth(KeyWidthType.STANDARD)
        val WIDE      = KeyWidth(KeyWidthType.WIDE)
        val EXTRA_WIDE = KeyWidth(KeyWidthType.EXTRA_WIDE)
        val FLEXIBLE  = KeyWidth(KeyWidthType.FLEXIBLE)
        fun fixed(dp: Float) = KeyWidth(KeyWidthType.FIXED, dp)
    }
}

data class KeyData(
    val primary: String,
    val alternates: List<String> = emptyList(),
    val type: KeyType = KeyType.CHARACTER,
    val width: KeyWidth = KeyWidth.STANDARD
)

data class KeyboardLayer(val id: String, val rows: List<List<KeyData>>)

object KeyboardLayoutData {

    // ------------------------------------------------------------------  default

    val defaultLayer = KeyboardLayer("default", listOf(
        // Row 1 — 11 keys
        listOf(
            KeyData("ض"), KeyData("ص"), KeyData("ث"), KeyData("ق"), KeyData("ف"),
            KeyData("غ"), KeyData("ع"),
            KeyData("ه", listOf("ـہـ", "ـہ", "ھ", "ة", "ۂ")),
            KeyData("خ"), KeyData("ح"),
            KeyData("ج", listOf("چ", "چھے"))
        ),
        // Row 2 — 10 keys
        listOf(
            KeyData("ش"), KeyData("س"),
            KeyData("ي", listOf("ئ", "ى", "ے")),
            KeyData("ب"),
            KeyData("ل", listOf("لا", "لأ", "لإ", "لآ", "لاٰ")),
            KeyData("ا", listOf("أ", "إ", "آ", "اٰ")),
            KeyData("ت"), KeyData("ن"), KeyData("م"),
            KeyData("ك", listOf("گ"))
        ),
        // Row 3 — shift + 8 chars + backspace
        listOf(
            KeyData("⇧", type = KeyType.SHIFT, width = KeyWidth.WIDE),
            KeyData("ذ"), KeyData("ظ"),
            KeyData("ؤ", listOf("ۚ", "ۨ")),
            KeyData("ر", listOf("ڑ")),
            KeyData("ز", listOf("ظ", "ژ")),
            KeyData("و", listOf("ة", "ۃ")),
            KeyData("ط"),
            KeyData("د", listOf("ڈ", "ذ")),
            KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.WIDE)
        ),
        // Row 4 — utility row
        listOf(
            KeyData("١٢٣", type = KeyType.NUMERIC, width = KeyWidth.fixed(80f)),
            KeyData("🌐", type = KeyType.GLOBE, width = KeyWidth.fixed(44f)),
            KeyData("ى"),
            KeyData("اعراب", alternates = listOf("َ", "ِ", "ُ", "ْ", "ٰ", "ً", "ٍ", "ٌ"), width = KeyWidth.fixed(70f)),
            KeyData(" ", type = KeyType.SPACE, width = KeyWidth.FLEXIBLE),
            KeyData(".", alternates = listOf(".", "!", "؟", "،", "؛", "٬"), width = KeyWidth.fixed(44f)),
            KeyData("ء"),
            KeyData("↵", type = KeyType.ENTER, width = KeyWidth.fixed(80f))
        )
    ))

    // ------------------------------------------------------------------ shift

    val shiftLayer = KeyboardLayer("shift", listOf(
        listOf(
            KeyData("َ"), KeyData("ُ"), KeyData("ٗ"), KeyData("ؕ"), KeyData("ؐ"),
            KeyData("ؑ"), KeyData("ﷺ"), KeyData("ھ"), KeyData("ژ"), KeyData("چھے"), KeyData("چ")
        ),
        listOf(
            KeyData("ِ"), KeyData("ٰ"), KeyData("ے"), KeyData("پ"), KeyData("ﷻ"),
            KeyData("ؓ"), KeyData("ـ"), KeyData("،"), KeyData("ں"), KeyData("گ")
        ),
        listOf(
            KeyData("⇧", type = KeyType.SHIFT, width = KeyWidth.WIDE),
            KeyData("ْ"), KeyData("ٖ"), KeyData("ۚ"), KeyData("ڑ"), KeyData("ؒ"),
            KeyData("ٹ"), KeyData("ڈ"),
            KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.WIDE)
        ),
        listOf(
            KeyData("١٢٣", type = KeyType.NUMERIC, width = KeyWidth.fixed(80f)),
            KeyData("🌐", type = KeyType.GLOBE, width = KeyWidth.fixed(44f)),
            KeyData(" ", type = KeyType.SPACE, width = KeyWidth.FLEXIBLE),
            KeyData("۞"),
            KeyData("↵", type = KeyType.ENTER, width = KeyWidth.fixed(80f))
        )
    ))

    // ------------------------------------------------------------------ numeric

    val numericLayer = KeyboardLayer("numeric", listOf(
        listOf(
            KeyData("1", listOf("١", "૧")), KeyData("2", listOf("٢", "૨")),
            KeyData("3", listOf("٣", "૩")), KeyData("4", listOf("٤", "૪")),
            KeyData("5", listOf("٥", "૫")), KeyData("6", listOf("٦", "૬")),
            KeyData("7", listOf("٧", "૭")), KeyData("8", listOf("٨", "૮")),
            KeyData("9", listOf("٩", "૯")), KeyData("0", listOf("٠", "૰"))
        ),
        listOf(
            KeyData("$", listOf("₨", "¥", "؋", "؈", "૱")), KeyData("#"),
            KeyData("%", listOf("٪")), KeyData("^"), KeyData("<"), KeyData(">"),
            KeyData("+", listOf("×")), KeyData("="),
            KeyData("*", listOf("٭")), KeyData("-", listOf("÷", "_"))
        ),
        listOf(
            KeyData("@"), KeyData("("), KeyData(")"),
            KeyData("؏"), KeyData("ؔ"), KeyData("؃"),
            KeyData("؂", listOf("؎")), KeyData("؁", listOf("؄")),
            KeyData("؀", listOf("۝", "۩")),
            KeyData("⌫", type = KeyType.BACKSPACE, width = KeyWidth.WIDE)
        ),
        listOf(
            KeyData("ا ب ج", type = KeyType.ABC, width = KeyWidth.fixed(80f)),
            KeyData("🌐", type = KeyType.GLOBE, width = KeyWidth.fixed(44f)),
            KeyData(" ", type = KeyType.SPACE, width = KeyWidth.FLEXIBLE),
            KeyData("↵", type = KeyType.ENTER, width = KeyWidth.fixed(80f))
        )
    ))
}
