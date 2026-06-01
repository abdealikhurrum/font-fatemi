import Foundation

struct VerbPrompt {
    let urduInfinitive: String
    let urduMeaning: String
    let label: String
    let urduWord: String
    let urduRoman: String
}

enum VerbPrompts {

    static let all: [VerbPrompt] = [
        karna, jana, ana, dena, lena, hona, kehna, dekhna, khana
    ].flatMap { $0 }

    private static func forms(
        _ inf: String, _ meaning: String,
        _ rows: [(String, String, String)]
    ) -> [VerbPrompt] {
        rows.map { VerbPrompt(urduInfinitive: inf, urduMeaning: meaning,
                              label: $0.0, urduWord: $0.1, urduRoman: $0.2) }
    }

    static let karna = forms("کرنا", "to do", [
        ("infinitive",   "کرنا",   "karna"),
        ("present-m-sg", "کرتا",   "karta"),
        ("present-f-sg", "کرتی",   "karti"),
        ("past-m-sg",    "کیا",    "kiya"),
        ("past-f-sg",    "کی",     "ki"),
        ("past-pl",      "کیے",    "kiye"),
        ("future",       "کرے گا", "karega"),
        ("imperative",   "کرو",    "karo"),
    ])

    static let jana = forms("جانا", "to go", [
        ("infinitive",   "جانا",    "jana"),
        ("present-m-sg", "جاتا",    "jata"),
        ("present-f-sg", "جاتی",    "jati"),
        ("past-m-sg",    "گیا",     "gaya"),
        ("past-f-sg",    "گئی",     "gayi"),
        ("past-pl",      "گئے",     "gaye"),
        ("future",       "جائے گا", "jayega"),
        ("imperative",   "جاؤ",     "jao"),
    ])

    static let ana = forms("آنا", "to come", [
        ("infinitive",   "آنا",     "ana"),
        ("present-m-sg", "آتا",     "aata"),
        ("present-f-sg", "آتی",     "aati"),
        ("past-m-sg",    "آیا",     "aaya"),
        ("past-f-sg",    "آئی",     "aayi"),
        ("past-pl",      "آئے",     "aaye"),
        ("future",       "آئے گا",  "aayega"),
        ("imperative",   "آؤ",      "aao"),
    ])

    static let dena = forms("دینا", "to give", [
        ("infinitive",   "دینا",   "dena"),
        ("present-m-sg", "دیتا",   "deta"),
        ("present-f-sg", "دیتی",   "deti"),
        ("past-m-sg",    "دیا",    "diya"),
        ("past-f-sg",    "دی",     "di"),
        ("past-pl",      "دیے",    "diye"),
        ("future",       "دے گا",  "dega"),
        ("imperative",   "دو",     "do"),
    ])

    static let lena = forms("لینا", "to take", [
        ("infinitive",   "لینا",   "lena"),
        ("present-m-sg", "لیتا",   "leta"),
        ("present-f-sg", "لیتی",   "leti"),
        ("past-m-sg",    "لیا",    "liya"),
        ("past-f-sg",    "لی",     "li"),
        ("past-pl",      "لیے",    "liye"),
        ("future",       "لے گا",  "lega"),
        ("imperative",   "لو",     "lo"),
    ])

    static let hona = forms("ہونا", "to be", [
        ("infinitive",   "ہونا",   "hona"),
        ("present-m-sg", "ہوتا",   "hota"),
        ("present-f-sg", "ہوتی",   "hoti"),
        ("past-m-sg",    "ہوا",    "hua"),
        ("past-f-sg",    "ہوئی",   "hui"),
        ("past-pl",      "ہوئے",   "huye"),
        ("future",       "ہو گا",  "hoga"),
        ("imperative",   "ہو",     "ho"),
    ])

    static let kehna = forms("کہنا", "to say", [
        ("infinitive",   "کہنا",    "kehna"),
        ("present-m-sg", "کہتا",    "kehta"),
        ("present-f-sg", "کہتی",    "kehti"),
        ("past-m-sg",    "کہا",     "kaha"),
        ("past-f-sg",    "کہی",     "kahi"),
        ("past-pl",      "کہے",     "kahe"),
        ("future",       "کہے گا",  "kahega"),
        ("imperative",   "کہو",     "kaho"),
    ])

    static let dekhna = forms("دیکھنا", "to see", [
        ("infinitive",   "دیکھنا",   "dekhna"),
        ("present-m-sg", "دیکھتا",   "dekhta"),
        ("present-f-sg", "دیکھتی",   "dekhti"),
        ("past-m-sg",    "دیکھا",    "dekha"),
        ("past-f-sg",    "دیکھی",    "dekhi"),
        ("past-pl",      "دیکھے",    "dekhe"),
        ("future",       "دیکھے گا", "dekhega"),
        ("imperative",   "دیکھو",    "dekho"),
    ])

    static let khana = forms("کھانا", "to eat", [
        ("infinitive",   "کھانا",    "khana"),
        ("present-m-sg", "کھاتا",    "khata"),
        ("present-f-sg", "کھاتی",    "khati"),
        ("past-m-sg",    "کھایا",    "khaya"),
        ("past-f-sg",    "کھائی",    "khayi"),
        ("past-pl",      "کھائے",    "khaye"),
        ("future",       "کھائے گا", "khayega"),
        ("imperative",   "کھاؤ",     "khao"),
    ])
}
