import Foundation

// MARK: - Layout data (ported from iOS LSDLearningKB/KeyData.swift)
// The macOS IME operates on a physical Arabic keyboard, so KeyType and KeyWidth
// are retained for completeness but only .character keys participate in the
// double-press lookup; all other keys are passed through to the app.

enum KeyType {
    case character
    case backspace, space, enter
    case numeric, abc, globe, emoji, diacritic
    case cursorLeft, cursorRight
}

struct KeyData {
    let primary: String
    let secondary: String
    let alternates: [String]
    let type: KeyType

    init(_ primary: String,
         secondary: String = "",
         alternates: [String] = [],
         type: KeyType = .character) {
        self.primary    = primary
        self.secondary  = secondary
        self.alternates = alternates
        self.type       = type
    }
}

// MARK: - Double-press lookup
//
// Returns the secondary character for a double-press, honouring current settings:
//   - doublePressEnabled    \u{2014} returns nil for everything when off  // —
//   - selectedLayout        \u{2014} switches between LSD/Arabic-Standard map and CRULP map  // —
//   - doubleAlefStyle       \u{2014} \u{0627}\u{0627} \u{2192} \u{0627}\u{0670} (kharo zabar, default) or \u{0622} (alef madda)  // — ا → ٰ آ
//   - urduYehStyle          \u{2014} which code-point is "yeh" in the CRULP map  // —
//
// LSD / Arabic-Standard secondaries:
//   Official rules (lsd.kmn):  \u{0633}\u{0633}\u{2192}\u{06D2}  \u{0636}\u{0636}\u{2192}\u{0679}  \u{0637}\u{0637}\u{2192}\u{06BA}  \u{0638}\u{0638}\u{2192}\u{06C1}  \u{062D}\u{062D}\u{2192}\u{0686}  \u{062B}\u{062B}\u{2192}\u{067E}  \u{0643}\u{0643}\u{2192}\u{06AF}  // س → ے ض ٹ ط ں ظ ہ ح چ ث پ ك گ
//   Extended:                  \u{0627}\u{0627}\u{2192}\u{0627}\u{0670}  \u{0647}\u{0647}\u{2192}\u{06BE}  \u{064A}\u{064A}\u{2192}\u{0626}  \u{0631}\u{0631}\u{2192}\u{0691}  \u{062F}\u{062F}\u{2192}\u{0688}  \u{0629}\u{0629}\u{2192}\u{06C3}  \u{062C}\u{062C}\u{2192}\u{0686}\u{06BE}\u{06D2}  // ا → ٰ ه ھ ي ئ ر ڑ د ڈ ة ۃ ج چ ے
//
// CRULP Urdu secondaries (phonetic positions):
//   \u{0639}\u{0639}\u{2192}\u{063A}  \u{0631}\u{0631}\u{2192}\u{0691}  \u{062A}\u{062A}\u{2192}\u{0679}  \u{062D}\u{062D}\u{2192}\u{062E}  \u{062F}\u{062F}\u{2192}\u{0688}  \u{06C1}\u{06C1}\u{2192}\u{06BE}  \u{0632}\u{0632}\u{2192}\u{0630}  \u{0634}\u{0634}\u{2192}\u{0636}  \u{0646}\u{0646}\u{2192}\u{06BA}  // ع → غ ر ڑ ت ٹ ح خ د ڈ ہ ھ ز ذ ش ض ن ں

extension KeyData {
    // Applies active character-style settings to an output character.
    // Runs for every layout so the user can mix Urdu/Arabic codepoints as needed.
    static func applyCharStyle(_ ch: String) -> String {
        var r = ch
        if KeyboardSettings.urduYehStyle      == .farsiYeh       { r = r.replacingOccurrences(of: "\u{064A}", with: "\u{06CC}") }  // ي→ی
        if KeyboardSettings.urduKaafStyle     == .urduKaaf        { r = r.replacingOccurrences(of: "\u{0643}", with: "\u{06A9}") }  // ك→ک
        if KeyboardSettings.urduHaaStyle      == .heGoal          { r = r.replacingOccurrences(of: "\u{0647}", with: "\u{06C1}") }  // ه→ہ
        if KeyboardSettings.urduTaaMarbutaStyle == .urduTaaMarbuta { r = r.replacingOccurrences(of: "\u{0629}", with: "\u{06C3}") }  // ة→ۃ
        return r
    }

    // Reverses applyCharStyle so that the secondary lookup always receives
    // the Arabic base codepoint, regardless of active style toggles.
    private static func unapplyCharStyle(_ ch: String) -> String {
        var r = ch
        if KeyboardSettings.urduYehStyle      == .farsiYeh       { r = r.replacingOccurrences(of: "\u{06CC}", with: "\u{064A}") }  // ی→ي
        if KeyboardSettings.urduKaafStyle     == .urduKaaf        { r = r.replacingOccurrences(of: "\u{06A9}", with: "\u{0643}") }  // ک→ك
        if KeyboardSettings.urduHaaStyle      == .heGoal          { r = r.replacingOccurrences(of: "\u{06C1}", with: "\u{0647}") }  // ہ→ه
        if KeyboardSettings.urduTaaMarbutaStyle == .urduTaaMarbuta { r = r.replacingOccurrences(of: "\u{06C3}", with: "\u{0629}") }  // ۃ→ة
        return r
    }

    static func secondary(for char: String) -> String? {
        guard KeyboardSettings.doublePressEnabled else { return nil }
        let base = unapplyCharStyle(char)   // always look up Arabic base forms
        switch KeyboardSettings.selectedLayout {
        case .crulpUrdu: return crulpSecondary(for: base)
        default:         return lsdSecondary(for: base)
        }
    }

    private static func lsdSecondary(for char: String) -> String? {
        let alef = KeyboardSettings.doubleAlefStyle == .alefMadda ? "\u{0622}" : "\u{0627}\u{0670}"  // آ ا ٰ
        switch char {
        case "\u{0636}": return "\u{0679}"  // ض ٹ
        case "\u{062B}": return "\u{067E}"  // ث پ
        case "\u{0647}": return "\u{06BE}"  // ه ھ
        case "\u{062D}": return "\u{0686}"  // ح چ
        case "\u{062C}": return "\u{0686}\u{06BE}\u{06D2}"  // ج چ ھ ے
        case "\u{0633}": return "\u{06D2}"  // س ے
        case "\u{064A}": return "\u{0626}"  // ي ئ
        case "\u{0627}": return alef  // ا
        case "\u{0643}": return "\u{06AF}"  // ك گ
        case "\u{0637}": return "\u{06BA}"  // ط ں
        case "\u{0631}": return "\u{0691}"  // ر ڑ
        case "\u{0629}": return "\u{06C3}"  // ة ۃ
        case "\u{062F}": return "\u{0688}"  // د ڈ
        case "\u{0638}": return "\u{06C1}"  // ظ ہ
        default:  return nil
        }
    }

    private static func crulpSecondary(for char: String) -> String? {
        switch char {
        case "\u{0639}": return "\u{063A}"  // ع غ
        case "\u{0631}": return "\u{0691}"  // ر ڑ
        case "\u{062A}": return "\u{0679}"  // ت ٹ
        case "\u{062D}": return "\u{062E}"  // ح خ
        case "\u{062F}": return "\u{0688}"  // د ڈ
        case "\u{0647}": return "\u{06BE}"  // ه ھ  (receives Arabic base after unapplyCharStyle)
        case "\u{0632}": return "\u{0630}"  // ز ذ
        case "\u{0634}": return "\u{0636}"  // ش ض
        case "\u{0646}": return "\u{06BA}"  // ن ں
        default:  return nil
        }
    }
}

// MARK: - Key-code \u{2192} character mapping  // →

extension KeyData {

    // Returns the Arabic/Urdu character for a physical key code + modifier combination,
    // honouring the currently selected layout. Returns nil for unmapped keys (function
    // keys, arrows, modifier-only presses, etc.) so the IME can pass them through.
    static func char(forCode code: Int, shift: Bool, option: Bool) -> String? {
        let layout = KeyboardSettings.selectedLayout
        let normalBase = layout == .macLsd ? macLsdNormalLayer : normalLayer
        let shiftBase  = layout == .macLsd ? macLsdShiftLayer  : shiftLayer
        let base: [Int: String]
        switch (shift, option) {
        case (true,  true):  base = shiftOptionLayer
        case (false, true):  base = optionLayer
        case (true,  false): base = shiftBase
        default:             base = normalBase
        }
        guard let ch = base[code] else { return nil }
        return applyCharStyle(ch)   // apply yeh/kaaf/haa/taa-marbuta style swaps (all layouts)
    }

    // MARK: Windows LSD layers (default \u{2014} maqalaAra.klc)  // —
    // Mac virtual key codes used below:
    //   `=50  1=18 2=19 3=20 4=21 5=23 6=22 7=26 8=28 9=25 0=29 -=27 ==24
    //   Q=12 W=13 E=14 R=15 Y=16 T=17 U=32 I=34 O=31 P=35 [=33 ]=30  (Y=16, T=17 on Mac)
    //   A=0  S=1  D=2  F=3  G=5  H=4  J=38 K=40 L=37 ;=41 '=39
    //   Z=6  X=7  C=8  V=9  B=11 N=45 M=46 ,=43 .=47 /=44
    // Layer 2 (no modifier) \u{2014} Windows LSD / maqalaAra.klc  // —
    private static let normalLayer: [Int: String] = [
        0: "\u{0634}",  1: "\u{0633}",  2: "\u{064A}",  3: "\u{0628}",  4: "\u{0627}",  5: "\u{0644}",  // ش س ي ب ا ل
        6: "\u{0626}",  7: "\u{0621}",  8: "\u{0624}",  9: "\u{0631}",  11: "\u{0644}\u{0627}",  // ئ ء ؤ ر ل ا
        12: "\u{0636}", 13: "\u{0635}", 14: "\u{062B}", 15: "\u{0642}", 16: "\u{063A}", 17: "\u{0641}",  // ض ص ث ق غ ف  (16=Y 17=T)
        18: "\u{0661}", 19: "\u{0662}", 20: "\u{0663}", 21: "\u{0664}", 22: "\u{0666}", 23: "\u{0665}",  // ١ ٢ ٣ ٤ ٦ ٥
        24: "=",  25: "\u{0669}", 26: "\u{0667}", 27: "-",  28: "\u{0668}", 29: "\u{0660}",  // ٩ ٧ ٨ ٠
        30: "\u{062F}", 31: "\u{062E}", 32: "\u{0639}", 33: "\u{062C}",  34: "\u{0647}", 35: "\u{062D}",  // د خ ع ج ه ح
        37: "\u{0645}", 38: "\u{062A}", 39: "\u{0637}", 40: "\u{0646}",  41: "\u{0643}",  // م ت ط ن ك
        42: "\\", 43: "\u{0648}", 44: "\u{0638}",  45: "\u{0649}", 46: "\u{0629}", 47: "\u{0632}",  // و ظ ى ة ز
        50: "\u{0630}",  // ذ
    ]

    // Layer 3 (shift) \u{2014} sourced from the Windows LSD keyboard (maqalaAra.klc)  // —
    private static let shiftLayer: [Int: String] = [
        // QWERTY row
        12: "\u{064E}", 13: "\u{064B}", 14: "\u{064F}", 15: "\u{064C}",
        16: "\u{0625}", 17: "\u{06A4}",  // Y=إ  T=ڤ  (16=Y 17=T)
        32: "\u{0657}", 34: "\u{06BE}",
        31: "\u{0679}", 35: "\u{06C1}",
        33: "\u{0686}", 30: "\u{0688}",
        // ASDF row
        0: "\u{0650}", 1: "\u{064D}", 2: "\u{06D2}", 3: "\u{067E}",
        4: "\u{0623}", 38: "\u{0640}", 40: "\u{060C}", 37: "/",
        41: ":", 39: "\"",
        // Backtick
        50: "\u{0651}",
        // ZXCV row
        6: "\u{0670}", 7: "\u{0652}", 8: "\u{0656}",
        9: "\u{0691}", 11: ":", 45: "\u{0622}", 46: "\u{06C3}",
        43: "\u{0613}", 47: ".", 44: "\u{061F}",
        42: "|",
        // Number row shifts
        18: "!", 19: "@", 20: "#", 21: "$", 22: "^", 23: "\u{066A}",  // ٪
        24: "+", 25: ")", 26: "&", 27: "_", 28: "*", 29: "(",
    ]

    // Layer 4 (option) — punctuation, brackets, dashes, quotation marks, BiDi controls.
    // Keys 37 (L) and 35 (P) are intercepted by optionSubtendingLayer before this layer
    // is consulted, so those entries are documentational only (never reached).
    private static let optionLayer: [Int: String] = [
        49: "\u{00A0}",   // \u{2325}Space \u{2192} NBSP  non-breaking space  // ⌥ →

        // Number row \u{2014} BiDi controls on 1\u{20137}, dashes on - and =  // — –
        18: "\u{200E}",   // \u{2325}1 \u{2192} LRM   left-to-right mark  // ⌥ →
        19: "\u{200F}",   // \u{2325}2 \u{2192} RLM   right-to-left mark  // ⌥ →
        20: "\u{2066}",   // \u{2325}3 \u{2192} LRI   left-to-right isolate  // ⌥ →
        21: "\u{2067}",   // \u{2325}4 \u{2192} RLI   right-to-left isolate  // ⌥ →
        23: "\u{2069}",   // \u{2325}5 \u{2192} PDI   pop directional isolate  // ⌥ →
        22: "\u{200D}",   // \u{2325}6 \u{2192} ZWJ   zero-width joiner  // ⌥ →
        26: "\u{200C}",   // \u{2325}7 \u{2192} ZWNJ  zero-width non-joiner  // ⌥ →
        27: "\u{2013}",   // \u{2325}- \u{2192} \u{2013}  en dash  // ⌥ → –
        24: "\u{2014}",   // \u{2325}= \u{2192} \u{2014}  em dash  // ⌥ → —

        // QWERTY row \u{2014} paired quotation marks and guillemets  // —
        12: "\u{2018}",   // \u{2325}Q \u{2192} \u{2018}  left single quotation mark  // ⌥ → '
        13: "\u{2019}",   // \u{2325}W \u{2192} \u{2019}  right single quotation mark  // ⌥ → '
        14: "\u{201C}",   // \u{2325}E \u{2192} \u{201C}  left double quotation mark  // ⌥ → "
        15: "\u{201D}",   // \u{2325}R \u{2192} \u{201D}  right double quotation mark  // ⌥ → "
        17: "\u{2026}",   // \u{2325}T \u{2192} \u{2026}  ellipsis  // ⌥ → …
        16: "\u{2022}",   // \u{2325}Y \u{2192} \u{2022}  bullet  // ⌥ → •
        32: "\u{2039}",   // \u{2325}U \u{2192} \u{2039}  single guillemet \u{2190}  // ⌥ → ‹ ←
        34: "\u{203A}",   // \u{2325}I \u{2192} \u{203A}  single guillemet \u{2192}  // ⌥ → › →
        31: "\u{00AB}",   // \u{2325}O \u{2192} \u{00AB}  double guillemet \u{2190}  // ⌥ → « ←
        // 35 (P) \u{2192} safha subtending (optionSubtendingLayer takes priority)  // →
        33: "\u{FD3E}",   // \u{2325}[ \u{2192} \u{FD3E}  Arabic ornate left parenthesis  // ⌥ → ﴾
        30: "\u{FD3F}",   // \u{2325}] \u{2192} \u{FD3F}  Arabic ornate right parenthesis  // ⌥ → ﴿

        // ASDF row \u{2014} bracket pairs and Arabic punctuation  // —
        0:  "\u{007B}",   // \u{2325}A \u{2192} {  left curly bracket  // ⌥ →
        1:  "\u{007D}",   // \u{2325}S \u{2192} }  right curly bracket  // ⌥ →
        2:  "\u{005B}",   // \u{2325}D \u{2192} [  left square bracket  // ⌥ →
        3:  "\u{005D}",   // \u{2325}F \u{2192} ]  right square bracket  // ⌥ →
        5:  "\u{003C}",   // \u{2325}G \u{2192} <  left angle  // ⌥ →
        4:  "\u{003E}",   // \u{2325}H \u{2192} >  right angle  // ⌥ →
        38: "\u{00A9}",   // \u{2325}J \u{2192} \u{00A9}  copyright  // ⌥ → ©
        40: "\u{00AE}",   // \u{2325}K \u{2192} \u{00AE}  registered  // ⌥ → ®
        // 37 (L) \u{2192} sanah subtending (optionSubtendingLayer takes priority)  // →
        41: "\u{061B}",   // \u{2325}; \u{2192} \u{061B}  Arabic semicolon  // ⌥ → ؛

        // ZXCV row \u{2014} typographic symbols and Arabic punctuation  // —
        6:  "\u{2015}",   // \u{2325}Z \u{2192} \u{2015}  horizontal bar  // ⌥ → ―
        7:  "\u{00B0}",   // \u{2325}X \u{2192} \u{00B0}  degree sign  // ⌥ → °
        8:  "\u{2122}",   // \u{2325}C \u{2192} \u{2122}  trademark  // ⌥ → ™
        9:  "\u{00B1}",   // \u{2325}V \u{2192} \u{00B1}  plus-minus  // ⌥ → ±
        11: "\u{00D7}",   // \u{2325}B \u{2192} \u{00D7}  multiplication sign  // ⌥ → ×
        45: "\u{00F7}",   // \u{2325}N \u{2192} \u{00F7}  division sign  // ⌥ → ÷
        46: "\u{00B7}",   // \u{2325}M \u{2192} \u{00B7}  middle dot  // ⌥ → ·
        43: "\u{060C}",   // \u{2325}, \u{2192} \u{060C}  Arabic comma  // ⌥ → ،
        44: "\u{061F}",   // \u{2325}/ \u{2192} \u{061F}  Arabic question mark  // ⌥ → ؟
        50: "\u{0640}",   // \u{2325}` \u{2192} \u{0640}  tatweel (kashida)  // ⌥ → ـ
    ]

    // Layer 5 (shift+option) \u{2014} sourced from the LSD Mac keylayout  // —
    private static let shiftOptionLayer: [Int: String] = [
        49: "\u{200C}",   // Shift+Option+Space \u{2192} ZWNJ (zero-width non-joiner)  // →
        1: "\u{06D2}",  2: "\u{06CC}",  3: "\u{067E}",  // ے ی پ
        8: "\u{0688}",  9: "\u{0691}",  11: "\u{0698}",  // ڈ ڑ ژ
        17: "\u{06A4}", 18: "\u{0638}",  // ڤ ظ
        27: "_",
        31: "\u{06D5}", 32: "\u{06D5}", 33: "\u{0686}",  // چ
        38: "\u{0679}",  40: "\u{06BA}",  41: "\u{06A9}",  // ٹ ں ک
        44: "\u{00F7}",  // ÷
    ]

    // MARK: Mac LSD layers (Lisan ud Dawat - Mac.keylayout)
    // Mac virtual key codes used below:
    //   `=50  1=18 2=19 3=20 4=21 5=23 6=22 7=26 8=28 9=25 0=29 -=27 ==24
    //   Q=12 W=13 E=14 R=15 Y=16 T=17 U=32 I=34 O=31 P=35 [=33 ]=30  (Y=16, T=17 on Mac)
    //   A=0  S=1  D=2  F=3  G=5  H=4  J=38 K=40 L=37 ;=41 '=39
    //   Z=6  X=7  C=8  V=9  B=11 N=45 M=46 ,=43 .=47 /=44
    // Layer 2 (no modifier) \u{2014} Mac LSD keylayout index 2  // —
    private static let macLsdNormalLayer: [Int: String] = [
        0: "\u{0634}",  1: "\u{0633}",  2: "\u{064A}",  3: "\u{0628}",  4: "\u{0627}",  5: "\u{0644}",  // ش س ي ب ا ل
        6: "\u{0638}",  7: "\u{0637}",  8: "\u{0630}",  9: "\u{062F}",  11: "\u{0632}",  // ظ ط ذ د ز
        12: "\u{0636}", 13: "\u{0635}", 14: "\u{062B}", 15: "\u{0642}", 16: "\u{063A}", 17: "\u{0641}",  // ض ص ث ق غ ف  (16=Y 17=T)
        18: "\u{0661}", 19: "\u{0662}", 20: "\u{0663}", 21: "\u{0664}", 22: "\u{0666}", 23: "\u{0665}",  // ١ ٢ ٣ ٤ ٦ ٥
        24: "=",  25: "\u{0669}", 26: "\u{0667}", 27: "-",  28: "\u{0668}", 29: "\u{0660}",  // ٩ ٧ ٨ ٠
        30: "\u{0629}", 31: "\u{062E}", 32: "\u{0639}", 33: "\u{062C}",  34: "\u{0647}", 35: "\u{062D}",  // ة خ ع ج ه ح
        37: "\u{0645}", 38: "\u{062A}", 39: "\u{061B}", 40: "\u{0646}",  41: "\u{0643}",  // م ت ؛ ن ك
        42: "\\", 43: "\u{060C}", 44: "/",  45: "\u{0631}", 46: "\u{0648}", 47: ".",  // ، ر و
        50: "\u{0640}",  // ـ
    ]

    // Layer 3 (shift) \u{2014} Mac LSD keylayout index 3  // —
    private static let macLsdShiftLayer: [Int: String] = [
        0: "\u{00BB}",  1: "\u{00AB}",  2: "\u{0649}",  4: "\u{0622}",  6: "'",  // » « ى آ
        8: "\u{0626}",  9: "\u{0621}",  11: "\u{0623}",  // ئ ء أ
        12: "\u{064E}", 13: "\u{064B}", 14: "\u{0650}",
        15: "\u{064D}", 16: "\u{064C}", 17: "\u{064F}",
        18: "!", 19: "@",  20: "#",  21: "$", 22: "^",  23: "\u{066A}",  // ٪
        24: "+", 25: ")",  26: "&",  27: "\u{0640}", 28: "*",  29: "(",  // ـ
        30: "{", 31: "\u{0652}", 32: "\u{0652}", 33: "}",
        34: "\u{0651}", 35: "[",
        37: "\u{066C}", 39: "\"", 40: "\u{066B}",
        41: ":", 42: "|",  43: ">", 44: "\u{061F}", 45: "\u{0625}", 46: "\u{0624}", 47: "<",  // ؟ إ ؤ
    ]

    // MARK: - Diacritic mode layers (Caps Lock)
    //
    // Layout philosophy: all base harakat reachable from the LEFT hand alone.
    //
    //   Left QWERTY:  Q=fatha  W=fathatan  E=damma  R=dammatan  T=hamza-above
    //   Left ASDF:    A=kasra  S=kasratan  D=maddah  F=kharo-zabar  G=hamza-below
    //   Left ZXCV:    Z=shadda  X=sukun  C=inv-damma  V=tatweel  B=ZWJ
    //   Backtick:     takhallus
    //
    //   Right QWERTY: small Quranic diacritics (Y U I O P [ ])
    //   Right ASDF:   small Quranic diacritics (H J K L) + SAWS/AS marks (; ')
    //   Right ZXCV:   document marks (N=ayah  M=rub-el-hizb  ,=sajda  .=sanah  /=safha)
    //   Number row:   Quranic pause/decoration marks (U+06D6 \u{2013} U+06E8)  // –
    //
    // Mac virtual key codes used below:
    //   `=50  1=18 2=19 3=20 4=21 5=23 6=22 7=26 8=28 9=25 0=29 -=27 ==24
    //   Q=12 W=13 E=14 R=15 Y=16 T=17 U=32 I=34 O=31 P=35 [=33 ]=30  (Y=16, T=17 on Mac)
    //   A=0  S=1  D=2  F=3  G=5  H=4  J=38 K=40 L=37 ;=41 '=39
    //   Z=6  X=7  C=8  V=9  B=11 N=45 M=46 ,=43 .=47 /=44
    private static let diacriticLayer: [Int: String] = [
        // \u{2500}\u{2500} Number row \u{2014} Quranic pause/decoration marks \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}  // ─ —
        18: "\u{06D6}",   // 1 \u{2192} small high lig \u{1E63}ad-lam-alef-maksura  // → ṣ
        19: "\u{06D7}",   // 2 \u{2192} small high lig qaf-lam-alef-maksura  // →
        20: "\u{06D8}",   // 3 \u{2192} small high meem initial form  // →
        21: "\u{06D9}",   // 4 \u{2192} small high lam alef  // →
        23: "\u{06DA}",   // 5 \u{2192} small high jeem  // →
        22: "\u{06DB}",   // 6 \u{2192} small high three dots  // →
        26: "\u{06DC}",   // 7 \u{2192} small high seen  // →
        28: "\u{06DF}",   // 8 \u{2192} small high rounded zero  // →
        25: "\u{06E0}",   // 9 \u{2192} small high upright rectangular zero  // →
        29: "\u{06E1}",   // 0 \u{2192} small high dotless head of khah  // →
        27: "\u{06E2}",   // - \u{2192} small high meem isolated  // →
        24: "\u{06E8}",   // = \u{2192} small high noon  // →

        // \u{2500}\u{2500} QWERTY row \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}  // ─
        // Left hand \u{2014} base harakat  // —
        12: "\u{064E}",   // Q \u{2192} fatha  // →
        13: "\u{064B}",   // W \u{2192} fathatan  // →
        14: "\u{064F}",   // E \u{2192} damma  // →
        15: "\u{064C}",   // R \u{2192} dammatan  // →
        17: "\u{0654}",   // T \u{2192} hamza above  (17=T on Mac)  // →
        // Right hand \u{2014} small Quranic diacritics  // —
        16: "\u{0618}",   // Y \u{2192} arabic small fatha  (16=Y on Mac)  // →
        32: "\u{061A}",   // U \u{2192} arabic small kasra  // →
        34: "\u{0619}",   // I \u{2192} arabic small damma  // →
        31: "\u{0615}",   // O \u{2192} arabic small high tah  // →
        35: "\u{06E4}",   // P \u{2192} arabic small high madda  // →
        33: "\u{06E3}",   // [ \u{2192} arabic small low seen  // →
        30: "\u{06ED}",   // ] \u{2192} arabic small low meem  // →

        // \u{2500}\u{2500} ASDF row \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}  // ─
        // Left hand \u{2014} base harakat (continued)  // —
        0:  "\u{0650}",   // A \u{2192} kasra  // →
        1:  "\u{064D}",   // S \u{2192} kasratan  // →
        2:  "\u{0653}",   // D \u{2192} maddah above  // →
        3:  "\u{0670}",   // F \u{2192} kharo zabar (superscript alef)  // →
        5:  "\u{0655}",   // G \u{2192} hamza below  // →
        // Right hand \u{2014} small Quranic diacritics (continued) + marks  // —
        4:  "\u{06E7}",   // H \u{2192} arabic small high yeh  // →
        38: "\u{06E5}",   // J \u{2192} arabic small waw  // →
        40: "\u{06E6}",   // K \u{2192} arabic small yeh  // →
        37: "\u{0616}",   // L \u{2192} arabic small high lig alef-lam-yeh  // →
        41: "\u{0610}",   // ; \u{2192} SAWS mark  // →
        39: "\u{0611}",   // ' \u{2192} AS mark  // →

        // \u{2500}\u{2500} ZXCV row \u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}\u{2500}  // ─
        50: "\u{0614}",   // ` \u{2192} takhallus (U+0614 arabic sign high waqf)  // →
        // Left hand \u{2014} base harakat (continued) + common joiners  // —
        6:  "\u{0651}",   // Z \u{2192} shadda (tashdeed)  // →
        7:  "\u{0652}",   // X \u{2192} sukun  // →
        8:  "\u{0657}",   // C \u{2192} arabic inverted damma  // →
        9:  "\u{0640}",   // V \u{2192} tatweel (kashida)  // →
        11: "\u{200D}",   // B \u{2192} ZWJ (zero-width joiner)  // →
        // Right hand \u{2014} document marks  // —
        45: "\u{06DD}",   // N \u{2192} end of ayah  // →
        46: "\u{06DE}",   // M \u{2192} rub el hizb  // →
        43: "^\u{0635}\u{0639}",   // , \u{2192} SA  // ص ع →
        47: "\u{0613}",   // . \u{2192} radia allah anhu/ridwan ullah alayhi  // →
        44: "^\u{0637}\u{0639}",   // / \u{2192} Taa Ayn with caret for easy find and replace  // ط ع →
    ]

    // Subtending mark triggers (Option layer, independent of Caps Lock).
    // Pressing one of these puts the IME into digit-collection mode;
    // the mark visually subtends over the following Arabic-Indic digit sequence.
    private static let optionSubtendingLayer: [Int: String] = [
        37: "\u{0601}",   // Option+L \u{2192} U+0601 ARABIC SIGN SANAH  (year subtending mark)  // →
        35: "\u{0603}",   // Option+P \u{2192} U+0603 ARABIC SIGN SAFHA  (page subtending mark)  // →
    ]

    static func optionSubtending(forCode code: Int) -> String? {
        return optionSubtendingLayer[code]
    }

    static func diacriticChar(forCode code: Int) -> String? {
        return diacriticLayer[code]
    }
}

// MARK: - Full layout (retained for reference; not rendered on macOS)

struct KeyboardLayer {
    let id: String
    let rows: [[KeyData]]
}

enum KeyboardLayoutData {

    static let defaultLayer = KeyboardLayer(id: "default", rows: [
        [
            KeyData("\u{0636}", secondary: "\u{0679}"),  // ض ٹ
            KeyData("\u{0635}"),  // ص
            KeyData("\u{062B}", secondary: "\u{067E}"),  // ث پ
            KeyData("\u{0642}"),  // ق
            KeyData("\u{0641}"),  // ف
            KeyData("\u{063A}"),  // غ
            KeyData("\u{0639}"),  // ع
            KeyData("\u{0647}", secondary: "\u{06BE}",  alternates: ["\u{0640}\u{06C1}\u{0640}", "\u{0640}\u{06C1}", "\u{06C2}"]),  // ه ھ ـ ہ ۂ
            KeyData("\u{062E}"),  // خ
            KeyData("\u{062D}", secondary: "\u{0686}"),  // ح چ
            KeyData("\u{062C}", secondary: "\u{0686}\u{06BE}\u{06D2}"),  // ج چ ھ ے
        ],
        [
            KeyData("\u{0634}"),  // ش
            KeyData("\u{0633}", secondary: "\u{06D2}"),  // س ے
            KeyData("\u{064A}", secondary: "\u{0626}",  alternates: ["\u{06D2}"]),  // ي ئ ے
            KeyData("\u{0628}"),  // ب
            KeyData("\u{0644}", alternates: ["\u{0644}\u{0627}", "\u{0644}\u{0623}", "\u{0644}\u{0625}", "\u{0644}\u{0622}", "\u{0644}\u{0627}\u{0670}"]),  // ل ا أ إ آ ٰ
            KeyData("\u{0627}", secondary: "\u{0627}\u{0670}", alternates: ["\u{0623}", "\u{0622}", "\u{0625}"]),  // ا ٰ أ آ إ
            KeyData("\u{062A}"),  // ت
            KeyData("\u{0646}"),  // ن
            KeyData("\u{0645}"),  // م
            KeyData("\u{0643}", secondary: "\u{06AF}",  alternates: ["\u{06AF}"]),  // ك گ
            KeyData("\u{0637}", secondary: "\u{06BA}"),  // ط ں
        ],
        [
            KeyData("\u{0626}"),  // ئ
            KeyData("\u{0621}"),  // ء
            KeyData("\u{0624}", alternates: ["\u{06DA}", "\u{06E8}"]),  // ؤ ۚ ۨ
            KeyData("\u{0631}", secondary: "\u{0691}",  alternates: ["\u{0691}"]),  // ر ڑ
            KeyData("\u{0649}"),  // ى
            KeyData("\u{0629}", secondary: "\u{06C3}"),  // ة ۃ
            KeyData("\u{0648}"),  // و
            KeyData("\u{0632}", alternates: ["\u{0698}", "\u{0630}"]),  // ز ژ ذ
            KeyData("\u{062F}", secondary: "\u{0688}",  alternates: ["\u{0688}"]),  // د ڈ
            KeyData("\u{0638}", secondary: "\u{06C1}"),  // ظ ہ
        ],
    ])
}
