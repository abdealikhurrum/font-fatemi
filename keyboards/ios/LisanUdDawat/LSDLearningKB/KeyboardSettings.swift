import Foundation

// Shared settings read by both the keyboard extension and the containing app.
// Add this file to BOTH the LSDLearningKB and LisanUdDawat targets in Xcode
// (same as PairCollector.swift — one source file, two target memberships).

enum KeyboardSettings {
    private static let appGroupID = "group.com.exordiumnetworks.lsdkeyboard"

    // Prediction bar — off by default until the transliteration model is live.
    static var predictionEnabled: Bool {
        get { UserDefaults(suiteName: appGroupID)?.bool(forKey: "prediction_enabled") ?? false }
        set { UserDefaults(suiteName: appGroupID)?.set(newValue, forKey: "prediction_enabled") }
    }
}
