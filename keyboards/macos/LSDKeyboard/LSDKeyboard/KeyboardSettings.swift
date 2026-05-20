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

    // MARK: - Urdu yeh style

    enum UrduYehStyle: String {
        case farsiYeh  = "farsi_yeh"    // ی  U+06CC  (default — standard Urdu/Farsi)
        case arabicYeh = "arabic_yeh"   // ي  U+064A
    }

    static var urduYehStyle: UrduYehStyle {
        get {
            UrduYehStyle(rawValue: UserDefaults.standard.string(
                forKey: "urdu_yeh_style") ?? "") ?? .farsiYeh
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "urdu_yeh_style") }
    }

    // MARK: - Layout

    enum LayoutType: String, CaseIterable {
        case lsd            = "lsd"
        case arabicStandard = "arabic_standard"
        case crulpUrdu      = "crulp_urdu"

        var label: String {
            switch self {
            case .lsd:            return "LSD (default)"
            case .arabicStandard: return "Arabic Standard"
            case .crulpUrdu:      return "CRULP Urdu"
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
