package com.exordiumnetworks.ligacheh

import android.graphics.Color

data class LessonStep(
    val heading: String,
    val body: String,
    val target: String = "",
    val keyHint: String = ""
)

data class LessonModule(
    val id: String,
    val title: String,
    val subtitle: String,
    val iconChar: String,   // shown large on the colored icon tile
    val accentColor: Int,
    val steps: List<LessonStep>
) {
    val stepCount get() = steps.size
}

object LessonCatalog {

    val all get() = listOf(doublePress, diacritics, joiners)

    fun byId(id: String) = all.first { it.id == id }

    // ------------------------------------------------------------------ module 1

    val doublePress = LessonModule(
        id          = "double_press",
        title       = "Double-press Characters",
        subtitle    = "Tap any key twice quickly to get its extended letter",
        iconChar    = "پ",
        accentColor = Color.parseColor("#1976D2"),
        steps = listOf(
            LessonStep(
                heading = "How double-press works",
                body = "This keyboard hides extended letters behind a quick double-tap on the same key. Tap a key twice in rapid succession and the second character replaces the first.\n\nEach step below shows the character and which key to double-press."
            ),
            LessonStep(
                heading = "پ — double-press ث",
                body = "Tap ث twice quickly. The keyboard replaces ث with پ.",
                target = "پاني", keyHint = "ث ث → پ"
            ),
            LessonStep(
                heading = "ٹ — double-press ض",
                body = "Tap ض twice quickly to get the retroflex ٹ.",
                target = "ٹھنڈا", keyHint = "ض ض → ٹ"
            ),
            LessonStep(
                heading = "چ — double-press ح",
                body = "Tap ح twice quickly to get چ.",
                target = "چائي", keyHint = "ح ح → چ"
            ),
            LessonStep(
                heading = "گ — double-press ك",
                body = "Tap ك twice quickly to get گ.",
                target = "گھر", keyHint = "ك ك → گ"
            ),
            LessonStep(
                heading = "ں — double-press ط",
                body = "Tap ط twice quickly to get the nasal ں.",
                target = "هاں", keyHint = "ط ط → ں"
            ),
            LessonStep(
                heading = "ہ — double-press ظ",
                body = "Tap ظ twice quickly to get ہ (do-chashmi he).",
                target = "همیشہ", keyHint = "ظ ظ → ہ"
            ),
            LessonStep(
                heading = "ھ — double-press ه",
                body = "Tap ه twice quickly to get the aspiration marker ھ.",
                target = "بھائي", keyHint = "ه ه → ھ"
            ),
            LessonStep(
                heading = "ڑ — double-press ر",
                body = "Tap ر twice quickly to get the retroflex ڑ.",
                target = "پهاڑو", keyHint = "ر ر → ڑ"
            ),
            LessonStep(
                heading = "ڈ — double-press د",
                body = "Tap د twice quickly to get the retroflex ڈ.",
                target = "ڈاکٹر", keyHint = "د د → ڈ"
            ),
            LessonStep(
                heading = "ے — double-press س",
                body = "Tap س twice quickly to get bari ye ے.",
                target = "کیے", keyHint = "س س → ے"
            ),
            LessonStep(
                heading = "اٰ — double-press ا",
                body = "Tap ا twice quickly to get alef with superscript alef اٰ, used in words like اٰمین.",
                target = "اٰمین", keyHint = "ا ا → اٰ"
            ),
            LessonStep(
                heading = "ۃ — double-press ة",
                body = "Tap ة twice quickly to get the Urdu form ۃ, used in words like رحمۃ.",
                target = "رحمۃ", keyHint = "ة ة → ۃ"
            ),
        )
    )

    // ------------------------------------------------------------------ module 2

    val diacritics = LessonModule(
        id          = "diacritics",
        title       = "Diacritics & Marks",
        subtitle    = "Add vowel marks and special symbols using the diacritics layer",
        iconChar    = "بَ",
        accentColor = Color.parseColor("#388E3C"),
        steps = listOf(
            LessonStep(
                heading = "The diacritics layer",
                body = "Tap the ـَ key (bottom row, second from right) to open the diacritics layer. Tap ا ب ج to return to letters.\n\nDiacritics are placed after the letter they mark — type a letter first, then the diacritic."
            ),
            LessonStep(
                heading = "فتحة — fatha (a-vowel)",
                body = "فتحة (fatha) marks a short /a/ vowel. It sits above the letter.",
                target = "بَ", keyHint = "ب then فتحة"
            ),
            LessonStep(
                heading = "كسرة — kasra (i-vowel)",
                body = "كسرة (kasra) marks a short /i/ vowel. It sits below the letter.",
                target = "بِ", keyHint = "ب then كسرة"
            ),
            LessonStep(
                heading = "ضمة — damma (u-vowel)",
                body = "ضمة (damma) marks a short /u/ vowel. It sits above the letter.",
                target = "بُ", keyHint = "ب then ضمة"
            ),
            LessonStep(
                heading = "سكون — sukun (no vowel)",
                body = "سكون (sukun) indicates a consonant with no following vowel.",
                target = "بْ", keyHint = "ب then سكون"
            ),
            LessonStep(
                heading = "شدة — shadda (gemination)",
                body = "شدة (shadda) doubles the consonant. It is written above the letter.",
                target = "بّ", keyHint = "ب then شدة"
            ),
            LessonStep(
                heading = "ﷺ — salawat symbol",
                body = "The diacritics layer includes ﷺ (sallallahu alayhi wasallam), a single-codepoint symbol used when writing the Prophet's name ﷺ.\n\nFind it in the second row of the diacritics layer.",
                target = "ﷺ", keyHint = "Diacritics layer → ﷺ"
            ),
            LessonStep(
                heading = "ؓ — radi symbol",
                body = "ؓ is a compact symbol for رضی اللّٰہ عنہ, placed after a companion's name.\n\nFind it in the second row of the diacritics layer.",
                target = "ؓ", keyHint = "Diacritics layer → ؓ"
            ),
        )
    )

    // ------------------------------------------------------------------ module 3

    val joiners = LessonModule(
        id          = "joiners",
        title       = "NBSP, ZWNJ & Tatweel",
        subtitle    = "Non-breaking space, zero-width non-joiner, and the elongation stroke",
        iconChar    = "ـ",
        accentColor = Color.parseColor("#7B1FA2"),
        steps = listOf(
            LessonStep(
                heading = "What is NBSP?",
                body = "Non-Breaking Space (NBSP, U+00A0) is like a regular space but prevents a line break between two words — useful to keep a name and its honorific (ﷺ) together on the same line.\n\nAccess it by long-pressing the space bar and sliding to NBSP.",
                keyHint = "Long-press space → NBSP"
            ),
            LessonStep(
                heading = "What is ZWNJ?",
                body = "Zero Width Non-Joiner (ZWNJ, U+200C) prevents two letters from joining, even when they normally would. Useful for showing a letter in its isolated form mid-word.\n\nAccess it by long-pressing the space bar and sliding to ZWNJ.",
                keyHint = "Long-press space → ZWNJ"
            ),
            LessonStep(
                heading = "ZWNJ: break a join",
                body = "م + ZWNJ + م: the second م appears isolated rather than joining the first. The example below shows the result.",
                target = "م‌م", keyHint = "م → ZWNJ → م"
            ),
            LessonStep(
                heading = "ـ — Tatweel (Kashida)",
                body = "Tatweel (ـ, U+0640) is the Arabic elongation stroke. It stretches the connecting baseline between two letters, used in calligraphic and display typography.\n\nUnlike NBSP/ZWNJ it is a visible character. Long-press the space bar and slide to ـ. Hold it down to insert multiple tatweels.",
                keyHint = "Long-press space → ـ"
            ),
            LessonStep(
                heading = "Tatweel in a word",
                body = "A tatweel sits between the س and the ل in this word, stretching the baseline for calligraphic effect.\n\nTry it anywhere using long-press space → ـ.",
                target = "سـلام", keyHint = "س → ـ → لام"
            ),
        )
    )
}
