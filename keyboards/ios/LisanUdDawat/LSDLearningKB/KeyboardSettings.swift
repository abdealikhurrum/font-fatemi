import Foundation

enum KeyboardSettings {
    // Shared with the main app via the App Group container so settings changed
    // in either place are visible to both.  Falls back to standard if the group
    // entitlement is not provisioned (e.g. during unit tests).
    static let defaults = UserDefaults(suiteName: "group.com.exordiumnetworks.lsdkeyboard") ?? .standard

    static var predictionEnabled: Bool {
        get { defaults.bool(forKey: "prediction_enabled") }
        set { defaults.set(newValue, forKey: "prediction_enabled") }
    }

    // Experimental: on the Latin layer, transliterate the typed Roman word
    // into LSD candidates in the predictive bar.
    static var translitEnabled: Bool {
        get { defaults.bool(forKey: "translit_enabled") }
        set { defaults.set(newValue, forKey: "translit_enabled") }
    }

    // Pause corpus collection without clearing stored data.
    static var corpusEnabled: Bool {
        get { defaults.object(forKey: "corpus_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "corpus_enabled") }
    }

    // Double-tap a key to insert its secondary character.
    static var doubleTapEnabled: Bool {
        get { defaults.object(forKey: "double_tap_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "double_tap_enabled") }
    }

    enum DelayPreset: String {
        case short  = "short"   // 0.25s
        case normal = "normal"  // 0.35s
        case long   = "long"    // 0.50s
        case custom = "custom"
    }

    static var doubleTapDelayPreset: DelayPreset {
        get { DelayPreset(rawValue: defaults.string(forKey: "double_tap_delay_preset") ?? "normal") ?? .normal }
        set { defaults.set(newValue.rawValue, forKey: "double_tap_delay_preset") }
    }

    // Actual delay in seconds; presets write here, custom stepper writes here directly.
    static var doubleTapDelay: TimeInterval {
        get {
            let v = defaults.double(forKey: "double_tap_delay")
            return v > 0 ? v : 0.35
        }
        set { defaults.set(newValue, forKey: "double_tap_delay") }
    }

    // CRULP Urdu yeh: Farsi yeh ی (no dots, U+06CC) vs Arabic yeh ي (two dots, U+064A).
    enum UrduYehStyle: String {
        case farsiYeh  = "farsi_yeh"    // ی  default — standard in Urdu/Farsi
        case arabicYeh = "arabic_yeh"   // ي
    }

    static var urduYehStyle: UrduYehStyle {
        get { UrduYehStyle(rawValue: defaults.string(forKey: "urdu_yeh_style") ?? "") ?? .arabicYeh }
        set { defaults.set(newValue.rawValue, forKey: "urdu_yeh_style") }
    }

    // Double alef (اا) produces either اٰ (alef with kharo zabar) or آ (alef madda).
    enum DoubleAlefStyle: String {
        case kharoZabar = "kharo_zabar"   // اٰ  default
        case alefMadda  = "alef_madda"    // آ
    }

    static var doubleAlefStyle: DoubleAlefStyle {
        get { DoubleAlefStyle(rawValue: defaults.string(forKey: "double_alef_style") ?? "") ?? .kharoZabar }
        set { defaults.set(newValue.rawValue, forKey: "double_alef_style") }
    }

    // Kaaf style: Arabic ك (U+0643) vs Urdu/Farsi ک (U+06A9).
    enum KaafStyle: String {
        case arabic = "arabic_kaaf"   // ك  default
        case urdu   = "urdu_kaaf"     // ک
    }

    static var kaafStyle: KaafStyle {
        get { KaafStyle(rawValue: defaults.string(forKey: "kaaf_style") ?? "") ?? .arabic }
        set { defaults.set(newValue.rawValue, forKey: "kaaf_style") }
    }

    // Haa style: Arabic ه (U+0647) vs Urdu He Goal ہ (U+06C1).
    enum HaaStyle: String {
        case arabic = "arabic_haa"    // ه  default
        case urdu   = "urdu_haa"      // ہ
    }

    static var haaStyle: HaaStyle {
        get { HaaStyle(rawValue: defaults.string(forKey: "haa_style") ?? "") ?? .arabic }
        set { defaults.set(newValue.rawValue, forKey: "haa_style") }
    }

    // Taa marbuta style: Arabic ة (U+0629) vs Urdu ۃ (U+06C3).
    enum TaaMarbuta: String {
        case arabic = "arabic_taa"    // ة  default
        case urdu   = "urdu_taa"      // ۃ
    }

    static var taaMarbuta: TaaMarbuta {
        get { TaaMarbuta(rawValue: defaults.string(forKey: "taa_marbuta") ?? "") ?? .arabic }
        set { defaults.set(newValue.rawValue, forKey: "taa_marbuta") }
    }

    // Active keyboard layout.
    enum LayoutType: String {
        case lsd            = "lsd"
        case arabicStandard = "arabic_standard"
        case crulpUrdu      = "crulp_urdu"
    }

    static var selectedLayout: LayoutType {
        get { LayoutType(rawValue: defaults.string(forKey: "selected_layout") ?? "lsd") ?? .lsd }
        set { defaults.set(newValue.rawValue, forKey: "selected_layout") }
    }

    // Long-press delay before the alternate-characters popup appears.
    // Presented as Short (0.20s) / Normal (0.35s) / Long (0.50s) in settings.
    static var longPressDelay: TimeInterval {
        get {
            let v = defaults.double(forKey: "long_press_delay")
            return v > 0 ? v : 0.35
        }
        set { defaults.set(newValue, forKey: "long_press_delay") }
    }

    // Interval at which a held long-press alternate auto-repeats. 0 = disabled.
    // Presented as Off / Slow (0.25s) / Fast (0.10s) in settings.
    static var popupRepeatInterval: TimeInterval {
        get {
            guard defaults.object(forKey: "popup_repeat_interval") != nil else { return 0.1 }
            return defaults.double(forKey: "popup_repeat_interval")
        }
        set { defaults.set(newValue, forKey: "popup_repeat_interval") }
    }

    // One-time tooltip for the BiDi fix button.
    static var biDiTooltipShown: Bool {
        get { defaults.bool(forKey: "bidi_tooltip_shown") }
        set { defaults.set(newValue, forKey: "bidi_tooltip_shown") }
    }

    // One-time tooltip for the Latin (AaBb) key.
    static var latinKeyTooltipShown: Bool {
        get { defaults.bool(forKey: "latin_key_tooltip_shown") }
        set { defaults.set(newValue, forKey: "latin_key_tooltip_shown") }
    }

    // Depth-gradient bevel on keys to simulate a forward-tilted physical surface.
    // Top of each key face is slightly shadowed; intensity varies by row.
    static var angledKeysEnabled: Bool {
        get { defaults.object(forKey: "angled_keys_enabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: "angled_keys_enabled") }
    }
}
