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
}
