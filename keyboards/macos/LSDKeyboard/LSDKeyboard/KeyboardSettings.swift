import Foundation

// UserDefaults-backed settings. Keys are identical to the iOS keyboard so
// preferences exported from one platform are readable on the other.

enum KeyboardSettings {

    // MARK: - Double-press

    static var doublePressEnabled: Bool {
        get { UserDefaults.standard.object(forKey: "double_tap_enabled") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "double_tap_enabled") }
    }

    enum DelayPreset: String, CaseIterable {
        case short  = "short"   // 0.25 s
        case normal = "normal"  // 0.35 s
        case long   = "long"    // 0.50 s

        var interval: TimeInterval {
            switch self {
            case .short:  return 0.25
            case .normal: return 0.35
            case .long:   return 0.50
            }
        }

        var label: String {
            switch self {
            case .short:  return "Short  (0.25 s)"
            case .normal: return "Normal (0.35 s)"
            case .long:   return "Long   (0.50 s)"
            }
        }
    }

    static var doublePressDelayPreset: DelayPreset {
        get {
            DelayPreset(rawValue: UserDefaults.standard.string(
                forKey: "double_tap_delay_preset") ?? "") ?? .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: "double_tap_delay_preset")
            doublePressDelay = newValue.interval
        }
    }

    static var doublePressDelay: TimeInterval {
        get {
            let v = UserDefaults.standard.double(forKey: "double_tap_delay")
            return v > 0 ? v : 0.35
        }
        set { UserDefaults.standard.set(newValue, forKey: "double_tap_delay") }
    }

    // MARK: - Double alef style

    enum DoubleAlefStyle: String {
        case kharoZabar = "kharo_zabar"   // اٰ  (default)
        case alefMadda  = "alef_madda"    // آ
    }

    static var doubleAlefStyle: DoubleAlefStyle {
        get {
            DoubleAlefStyle(rawValue: UserDefaults.standard.string(
                forKey: "double_alef_style") ?? "") ?? .kharoZabar
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "double_alef_style") }
    }

    // MARK: - Character style toggles
    //
    // Each setting swaps an Arabic base codepoint for its Urdu/Farsi variant.
    // Applies to ALL layouts (LSD Windows, LSD Mac, CRULP).

    // Yeh: ي U+064A (Arabic, default) ↔ ی U+06CC (Farsi/Urdu)
    enum UrduYehStyle: String {
        case farsiYeh  = "farsi_yeh"    // ی  U+06CC
        case arabicYeh = "arabic_yeh"   // ي  U+064A (default)
    }

    static var urduYehStyle: UrduYehStyle {
        get {
            UrduYehStyle(rawValue: UserDefaults.standard.string(
                forKey: "urdu_yeh_style") ?? "") ?? .arabicYeh
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "urdu_yeh_style") }
    }

    // Kaaf: ك U+0643 (Arabic, default) ↔ ک U+06A9 (Urdu)
    enum UrduKaafStyle: String {
        case arabicKaaf = "arabic_kaaf"  // ك  U+0643  (default)
        case urduKaaf   = "urdu_kaaf"    // ک  U+06A9
    }

    static var urduKaafStyle: UrduKaafStyle {
        get {
            UrduKaafStyle(rawValue: UserDefaults.standard.string(
                forKey: "urdu_kaaf_style") ?? "") ?? .arabicKaaf
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "urdu_kaaf_style") }
    }

    // Haa: ه U+0647 (Arabic, default) ↔ ہ U+06C1 (Urdu he goal)
    enum UrduHaaStyle: String {
        case arabicHaa = "arabic_haa"  // ه  U+0647  (default)
        case heGoal    = "he_goal"     // ہ  U+06C1
    }

    static var urduHaaStyle: UrduHaaStyle {
        get {
            UrduHaaStyle(rawValue: UserDefaults.standard.string(
                forKey: "urdu_haa_style") ?? "") ?? .arabicHaa
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "urdu_haa_style") }
    }

    // Taa marbuta: ة U+0629 (Arabic, default) ↔ ۃ U+06C3 (Urdu)
    enum UrduTaaMarbutaStyle: String {
        case arabicTaaMarbuta = "arabic_taa_marbuta"  // ة  U+0629  (default)
        case urduTaaMarbuta   = "urdu_taa_marbuta"    // ۃ  U+06C3
    }

    static var urduTaaMarbutaStyle: UrduTaaMarbutaStyle {
        get {
            UrduTaaMarbutaStyle(rawValue: UserDefaults.standard.string(
                forKey: "urdu_taa_marbuta_style") ?? "") ?? .arabicTaaMarbuta
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "urdu_taa_marbuta_style") }
    }

    // MARK: - Layout

    enum LayoutType: String, CaseIterable {
        case lsd       = "lsd"
        case macLsd    = "mac_lsd"
        case crulpUrdu = "crulp_urdu"

        var label: String {
            switch self {
            case .lsd:       return "LSD (Windows PC)"
            case .macLsd:    return "LSD (Mac)"
            case .crulpUrdu: return "CRULP Urdu"
            }
        }
    }

    static var selectedLayout: LayoutType {
        get {
            LayoutType(rawValue: UserDefaults.standard.string(
                forKey: "selected_layout") ?? "") ?? .lsd
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "selected_layout") }
    }
}
