import Foundation

enum KeyboardSettings {
    // Prediction bar — off by default until the transliteration model is live.
    // Uses standard UserDefaults (no App Group needed until the main-app settings
    // screen needs to share the value across the extension boundary).
    static var predictionEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "prediction_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "prediction_enabled") }
    }
}
