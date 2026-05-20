import Foundation

enum KeyboardSettings {
    static var predictionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "prediction_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "prediction_enabled") }
    }

    // Pause corpus collection without clearing stored data.
    static var corpusEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "corpus_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "corpus_enabled") }
    }

    // Double-tap a key to insert its secondary character.
    static var doubleTapEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "double_tap_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "double_tap_enabled") }
    }

    enum DelayPreset: String {
        case short  = "short"   // 0.25s
        case normal = "normal"  // 0.35s
        case long   = "long"    // 0.50s
        case custom = "custom"
    }

    static var doubleTapDelayPreset: DelayPreset {
        get { DelayPreset(rawValue: UserDefaults.standard.string(forKey: "double_tap_delay_preset") ?? "normal") ?? .normal }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "double_tap_delay_preset") }
    }

    // Actual delay in seconds; presets write here, custom stepper writes here directly.
    static var doubleTapDelay: TimeInterval {
        get {
            let v = UserDefaults.standard.double(forKey: "double_tap_delay")
            return v > 0 ? v : 0.35
        }
        set { UserDefaults.standard.set(newValue, forKey: "double_tap_delay") }
    }

    // CRULP Urdu yeh: Farsi yeh ی (no dots, U+06CC) vs Arabic yeh ي (two dots, U+064A).
    enum UrduYehStyle: String {
        case farsiYeh  = "farsi_yeh"    // ی  default — standard in Urdu/Farsi
        case arabicYeh = "arabic_yeh"   // ي
    }

    static var urduYehStyle: UrduYehStyle {
        get { UrduYehStyle(rawValue: UserDefaults.standard.string(forKey: "urdu_yeh_style") ?? "") ?? .farsiYeh }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "urdu_yeh_style") }
    }

    // Double alef (اا) produces either اٰ (alef with kharo zabar) or آ (alef madda).
    enum DoubleAlefStyle: String {
        case kharoZabar = "kharo_zabar"   // اٰ  default
        case alefMadda  = "alef_madda"    // آ
    }

    static var doubleAlefStyle: DoubleAlefStyle {
        get { DoubleAlefStyle(rawValue: UserDefaults.standard.string(forKey: "double_alef_style") ?? "") ?? .kharoZabar }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "double_alef_style") }
    }

    // Active keyboard layout.
    enum LayoutType: String {
        case lsd            = "lsd"
        case arabicStandard = "arabic_standard"
        case crulpUrdu      = "crulp_urdu"
    }

    static var selectedLayout: LayoutType {
        get { LayoutType(rawValue: UserDefaults.standard.string(forKey: "selected_layout") ?? "lsd") ?? .lsd }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "selected_layout") }
    }
}
