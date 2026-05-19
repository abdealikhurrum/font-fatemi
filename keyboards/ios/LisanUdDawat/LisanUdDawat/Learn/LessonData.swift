import UIKit

struct LessonStep {
    let heading: String
    let body: String
    let target: String    // empty = explanatory slide (Continue button); non-empty = typing exercise
    let keyHint: String   // shown as a badge below the target, e.g. "ث ث → پ"
}

struct LessonModule {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: UIColor
    let steps: [LessonStep]

    var exerciseCount: Int { steps.filter { !$0.target.isEmpty }.count }
}

enum LessonCatalog {

    static let modules: [LessonModule] = [doublePress, diacritics, joiners]

    // MARK: - Module 1: Double-press characters

    static let doublePress = LessonModule(
        id: "double_press",
        title: "Double-press Characters",
        subtitle: "Tap any key twice quickly to get its extended letter",
        systemImage: "hand.tap",
        accent: .systemBlue,
        steps: [
            LessonStep(
                heading: "How double-press works",
                body: "The LSD keyboard hides extended letters behind a quick double-tap on the same key. Tap a key twice in rapid succession and the second letter replaces the first with the correct character.\n\nEach exercise below asks you to type a word that contains one of these characters. Use the keyboard to produce it.",
                target: "",
                keyHint: ""
            ),
            // پ  (ث ث → پ)
            LessonStep(
                heading: "پ — double-press ث",
                body: "Tap ث twice quickly. The keyboard will replace ث with پ.\n\nType the word below:",
                target: "پانی",
                keyHint: "ث ث → پ"
            ),
            // ٹ  (ض ض → ٹ)
            LessonStep(
                heading: "ٹ — double-press ض",
                body: "Tap ض twice quickly to get the retroflex ٹ.\n\nType the word below:",
                target: "ٹھنڈا",
                keyHint: "ض ض → ٹ"
            ),
            // چ  (ح ح → چ)
            LessonStep(
                heading: "چ — double-press ح",
                body: "Tap ح twice quickly to get چ.\n\nType the word below:",
                target: "چائے",
                keyHint: "ح ح → چ"
            ),
            // گ  (ك ك → گ)
            LessonStep(
                heading: "گ — double-press ك",
                body: "Tap ك twice quickly to get گ.\n\nType the word below:",
                target: "گھر",
                keyHint: "ك ك → گ"
            ),
            // ں  (ط ط → ں)
            LessonStep(
                heading: "ں — double-press ط",
                body: "Tap ط twice quickly to get the nasal ں.\n\nType the word below:",
                target: "ہاں",
                keyHint: "ط ط → ں"
            ),
            // ہ  (ظ ظ → ہ)
            LessonStep(
                heading: "ہ — double-press ظ",
                body: "Tap ظ twice quickly to get ہ (do-chashmi he).\n\nType the word below:",
                target: "ہمیشہ",
                keyHint: "ظ ظ → ہ"
            ),
            // ھ  (ه ه → ھ)
            LessonStep(
                heading: "ھ — double-press ه",
                body: "Tap ه twice quickly to get the aspiration marker ھ.\n\nType the word below:",
                target: "بھائی",
                keyHint: "ه ه → ھ"
            ),
            // ڑ  (ر ر → ڑ)
            LessonStep(
                heading: "ڑ — double-press ر",
                body: "Tap ر twice quickly to get the retroflex ڑ.\n\nType the word below:",
                target: "لڑکی",
                keyHint: "ر ر → ڑ"
            ),
            // ڈ  (د د → ڈ)
            LessonStep(
                heading: "ڈ — double-press د",
                body: "Tap د twice quickly to get the retroflex ڈ.\n\nType the word below:",
                target: "ڈاکٹر",
                keyHint: "د د → ڈ"
            ),
            // ے  (س س → ے)
            LessonStep(
                heading: "ے — double-press س",
                body: "Tap س twice quickly to get bari ye ے.\n\nType the word below:",
                target: "کیے",
                keyHint: "س س → ے"
            ),
            // اٰ  (ا ا → اٰ)
            LessonStep(
                heading: "اٰ — double-press ا",
                body: "Tap ا twice quickly to get alef with madda above اٰ, used in words like اٰمین.\n\nType the word below:",
                target: "اٰمین",
                keyHint: "ا ا → اٰ"
            ),
            // ۃ  (ة ة → ۃ)
            LessonStep(
                heading: "ۃ — double-press ة",
                body: "Tap ة twice quickly to get the Urdu form ۃ, used in اللّٰہ.\n\nType the word below:",
                target: "رحمۃ",
                keyHint: "ة ة → ۃ"
            ),
        ]
    )

    // MARK: - Module 2: Diacritics & Marks

    static let diacritics = LessonModule(
        id: "diacritics",
        title: "Diacritics & Marks",
        subtitle: "Add vowel marks and special symbols using the diacritics layer",
        systemImage: "character.cursor.ibeam",
        accent: .systemGreen,
        steps: [
            LessonStep(
                heading: "The diacritics layer",
                body: "Tap the ـَ key (bottom-right of the main layer) to open the diacritics layer. Tap ا ب ج to return to letters.\n\nDiacritics are placed after the letter they mark. Type a letter first, then the diacritic.",
                target: "",
                keyHint: ""
            ),
            // Fatha
            LessonStep(
                heading: "فتحة — fatha (a-vowel)",
                body: "فتحة (fatha) marks a short /a/ vowel. It sits above the letter.\n\nSwitch to the diacritics layer and type the marked letter below:",
                target: "بَ",
                keyHint: "ب then فتحة"
            ),
            // Kasra
            LessonStep(
                heading: "كسرة — kasra (i-vowel)",
                body: "كسرة (kasra) marks a short /i/ vowel. It sits below the letter.\n\nType the marked letter below:",
                target: "بِ",
                keyHint: "ب then كسرة"
            ),
            // Damma
            LessonStep(
                heading: "ضمة — damma (u-vowel)",
                body: "ضمة (damma) marks a short /u/ vowel. It sits above the letter.\n\nType the marked letter below:",
                target: "بُ",
                keyHint: "ب then ضمة"
            ),
            // Sukun
            LessonStep(
                heading: "سكون — sukun (no vowel)",
                body: "سكون (sukun) indicates a consonant with no following vowel.\n\nType the marked letter below:",
                target: "بْ",
                keyHint: "ب then سكون"
            ),
            // Shadda
            LessonStep(
                heading: "شدة — shadda (gemination)",
                body: "شدة (shadda) doubles the consonant. It is written above the letter.\n\nType the marked letter below:",
                target: "بّ",
                keyHint: "ب then شدة"
            ),
            // Salawat
            LessonStep(
                heading: "ﷺ — salawat symbol",
                body: "The diacritics layer includes ﷺ (sallallahu alayhi wasallam), a single-codepoint symbol used when writing the Prophet's name ﷺ.\n\nFind it in the diacritics layer and type it below:",
                target: "ﷺ",
                keyHint: "Diacritics layer → ﷺ"
            ),
            // Radi
            LessonStep(
                heading: "ؓ — radi symbol",
                body: "ؓ is a compact symbol for رضی اللّٰہ عنہ, placed after a companion's name.\n\nFind it in the diacritics layer and type it below:",
                target: "ؓ",
                keyHint: "Diacritics layer → ؓ"
            ),
        ]
    )

    // MARK: - Module 3: ZWJ, ZWNJ & Tatweel

    static let joiners = LessonModule(
        id: "joiners",
        title: "Joiners & Tatweel",
        subtitle: "Invisible joiners and the elongation stroke — all on the space bar",
        systemImage: "link",
        accent: .systemPurple,
        steps: [
            LessonStep(
                heading: "What is ZWJ?",
                body: "Zero Width Joiner (ZWJ, U+200D) forces two letters to connect as if they were part of the same word, even when they normally wouldn't join.\n\nAccess it by long-pressing the space bar and sliding to ZWJ.",
                target: "",
                keyHint: "Long-press space → ZWJ"
            ),
            LessonStep(
                heading: "What is ZWNJ?",
                body: "Zero Width Non-Joiner (ZWNJ, U+200C) prevents two letters from joining, even when they normally would. This is useful for showing a letter in its isolated form mid-word.\n\nAccess it by long-pressing the space bar and sliding to ZWNJ.",
                target: "",
                keyHint: "Long-press space → ZWNJ"
            ),
            // ZWNJ exercise: م‌م (letters forced apart)
            LessonStep(
                heading: "ZWNJ: break a join",
                body: "Type م then ZWNJ then م. The second م will appear in isolated form instead of connecting to the first.\n\nThe result should look like two separate م glyphs side by side.",
                target: "م\u{200C}م",
                keyHint: "م → ZWNJ → م"
            ),
            // ZWJ exercise: ب‍ (forced medial form)
            LessonStep(
                heading: "ZWJ: force a joining form",
                body: "Type ب then ZWJ. The ب will display in its medial (connected) form even though nothing follows it — useful when showing how a letter looks inside a word.\n\nType the sequence below:",
                target: "ب\u{200D}",
                keyHint: "ب → ZWJ"
            ),
            // Tatweel explanation
            LessonStep(
                heading: "ـ — Tatweel (Kashida)",
                body: "Tatweel (ـ, U+0640) is the Arabic elongation stroke. It stretches the connecting baseline between two letters, used in calligraphic and display typography to justify lines or add visual weight.\n\nUnlike ZWJ/ZWNJ it is a visible character. Long-press the space bar and slide to ـ.\n\nYou can hold down on ـ in the popup to insert multiple tatweels in a row.",
                target: "",
                keyHint: "Long-press space → ـ"
            ),
            // Tatweel exercise: سـلام
            LessonStep(
                heading: "Practice: elongate a word",
                body: "Type the word below. A tatweel sits between the س and the ل, stretching the baseline for calligraphic effect.\n\nInsert it with long-press space → ـ.",
                target: "سـلام",
                keyHint: "س → ـ → لام"
            ),
        ]
    )
}
