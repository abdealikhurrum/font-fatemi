import UIKit

struct LessonStep {
    let heading: String
    let body: String
    let target: String    // example character or word shown as a large reference; empty = omit
    let keyHint: String   // badge below the target, e.g. "ث ث → پ"
}

struct LessonModule {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: UIColor
    let steps: [LessonStep]
    var isVerbTraining: Bool = false

    var stepCount: Int { steps.count }
}

enum LessonCatalog {

    static let modules: [LessonModule] = [verbTraining, doublePress, diacritics, joiners]

    static let verbTraining = LessonModule(
        id: "verb_training",
        title: "Verb Training",
        subtitle: "Type the LSD equivalent of each Urdu verb form to build the linguistic corpus",
        systemImage: "square.and.pencil",
        accent: .systemOrange,
        steps: [],
        isVerbTraining: true
    )

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
                body: "The LSD keyboard hides extended letters behind a quick double-tap on the same key. Tap a key twice in rapid succession and the second letter replaces the first with the correct character.\n\nEach step below shows the character and which key to double-press.",
                target: "",
                keyHint: ""
            ),
            LessonStep(
                heading: "پ — double-press ث",
                body: "Tap ث twice quickly. The keyboard will replace ث with پ.",
                target: "پاني",
                keyHint: "ث ث → پ"
            ),
            LessonStep(
                heading: "ٹ — double-press ض",
                body: "Tap ض twice quickly to get the retroflex ٹ.",
                target: "ٹھنڈا",
                keyHint: "ض ض → ٹ"
            ),
            LessonStep(
                heading: "چ — double-press ح",
                body: "Tap ح twice quickly to get چ.",
                target: "چائي",
                keyHint: "ح ح → چ"
            ),
            LessonStep(
                heading: "گ — double-press ك",
                body: "Tap ك twice quickly to get گ.",
                target: "گھر",
                keyHint: "ك ك → گ"
            ),
            LessonStep(
                heading: "ں — double-press ط",
                body: "Tap ط twice quickly to get the nasal ں.",
                target: "هاں",
                keyHint: "ط ط → ں"
            ),
            LessonStep(
                heading: "ہ — double-press ظ",
                body: "Tap ظ twice quickly to get ہ (do-chashmi he).",
                target: "همیشہ",
                keyHint: "ظ ظ → ہ"
            ),
            LessonStep(
                heading: "ھ — double-press ه",
                body: "Tap ه twice quickly to get the aspiration marker ھ.",
                target: "بھائي",
                keyHint: "ه ه → ھ"
            ),
            LessonStep(
                heading: "ڑ — double-press ر",
                body: "Tap ر twice quickly to get the retroflex ڑ.",
                target: "پهاڑو",
                keyHint: "ر ر → ڑ"
            ),
            LessonStep(
                heading: "ڈ — double-press د",
                body: "Tap د twice quickly to get the retroflex ڈ.",
                target: "ڈاکٹر",
                keyHint: "د د → ڈ"
            ),
            LessonStep(
                heading: "ے — double-press س",
                body: "Tap س twice quickly to get bari ye ے.",
                target: "کیے",
                keyHint: "س س → ے"
            ),
            LessonStep(
                heading: "اٰ — double-press ا",
                body: "Tap ا twice quickly to get alef + kharo zabar or alef with madda above اٰ (changeable in settings), used in words like اٰمین.",
                target: "اٰمین",
                keyHint: "ا ا → اٰ"
            ),
            LessonStep(
                heading: "ۃ — double-press ة",
                body: "Tap ة twice quickly to get the Urdu form ۃ, used in اللّٰہ.",
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
                body: "Tap the ـَ key (bottom-right of the main layer) to open the diacritics layer. Tap ا ب ج to return to letters.\n\nDiacritics are placed after the letter they mark — type a letter first, then the diacritic.",
                target: "",
                keyHint: ""
            ),
            LessonStep(
                heading: "فتحة — fatha (a-vowel)",
                body: "فتحة (fatha) marks a short /a/ vowel. It sits above the letter.",
                target: "بَ",
                keyHint: "ب then فتحة"
            ),
            LessonStep(
                heading: "كسرة — kasra (i-vowel)",
                body: "كسرة (kasra) marks a short /i/ vowel. It sits below the letter.",
                target: "بِ",
                keyHint: "ب then كسرة"
            ),
            LessonStep(
                heading: "ضمة — damma (u-vowel)",
                body: "ضمة (damma) marks a short /u/ vowel. It sits above the letter.",
                target: "بُ",
                keyHint: "ب then ضمة"
            ),
            LessonStep(
                heading: "سكون — sukun (no vowel)",
                body: "سكون (sukun) indicates a consonant with no following vowel.",
                target: "بْ",
                keyHint: "ب then سكون"
            ),
            LessonStep(
                heading: "شدة — shadda (gemination)",
                body: "شدة (shadda) doubles the consonant. It is written above the letter.",
                target: "بّ",
                keyHint: "ب then شدة"
            ),
            LessonStep(
                heading: "ﷺ — salawat symbol",
                body: "The diacritics layer includes ﷺ (sallallahu alayhi wasallam), a single-codepoint symbol used when writing the Prophet's name ﷺ.\n\nFind it in the diacritics layer.",
                target: "ﷺ",
                keyHint: "Diacritics layer → ﷺ"
            ),
            LessonStep(
                heading: "ؓ — radi symbol",
                body: "ؓ is a compact symbol for رضی اللّٰہ عنہ, placed after a companion's name.\n\nFind it in the diacritics layer.",
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
                body: "Zero Width Non-Joiner (ZWNJ, U+200C) prevents two letters from joining, even when they normally would. Useful for showing a letter in its isolated form mid-word.\n\nAccess it by long-pressing the space bar and sliding to ZWNJ.",
                target: "",
                keyHint: "Long-press space → ZWNJ"
            ),
            LessonStep(
                heading: "ZWNJ: break a join",
                body: "م + ZWNJ + م: the second م appears isolated rather than joining the first. The example shows the result.",
                target: "م\u{200C}م",
                keyHint: "م → ZWNJ → م"
            ),
            LessonStep(
                heading: "ZWJ: force a joining form",
                body: "ب + ZWJ: ب displays in medial (connected) form even though nothing follows — useful for showing how a letter looks inside a word.",
                target: "ب\u{200D}",
                keyHint: "ب → ZWJ"
            ),
            LessonStep(
                heading: "ـ — Tatweel (Kashida)",
                body: "Tatweel (ـ, U+0640) is the Arabic elongation stroke. It stretches the connecting baseline between two letters, used in calligraphic and display typography.\n\nUnlike ZWJ/ZWNJ it is a visible character. Long-press the space bar and slide to ـ. Hold it down to insert multiple tatweels.",
                target: "",
                keyHint: "Long-press space → ـ"
            ),
            LessonStep(
                heading: "Tatweel in a word",
                body: "A tatweel sits between the س and the ل in this word, stretching the baseline for calligraphic effect.\n\nTry it anywhere using long-press space → ـ.",
                target: "سـلام",
                keyHint: "س → ـ → لام"
            ),
        ]
    )
}
