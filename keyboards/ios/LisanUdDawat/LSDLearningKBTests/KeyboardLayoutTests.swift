// KeyboardLayoutTests.swift
//
// Verifies that every layout exposes all standard LSD characters from the
// default (letter) layer via primary tap or double-tap secondary — without
// requiring long-press, the numeric layer, or the diacritic layer.
//
// Xcode setup (one-time):
//   1. File → New → Target → Unit Testing Bundle → "LSDLearningKBTests"
//   2. Host Application: LisanUdDawat
//   3. Build Phases → Compile Sources — add:
//        LSDLearningKB/KeyData.swift
//        LSDLearningKB/ArabicStandardLayoutData.swift
//        LSDLearningKB/CRULPUrduLayoutData.swift
//   4. Add this file to the same target
//   5. Cmd+U to run

import XCTest

final class KeyboardLayoutTests: XCTestCase {

    // Characters the LSD keyboard exposes without mode switches or long-press.
    // Primaries = direct tap; secondaries = double-tap on the same key.
    // Update this list whenever the LSD base layer gains or loses a character.
    static let standardLSDCharacters: Set<String> = [
        // ── Row 1 primaries ────────────────────────────────────────────────
        "ض", "ص", "ث", "ق", "ف", "غ", "ع", "ه", "خ", "ح", "ج",
        // ── Row 2 primaries ────────────────────────────────────────────────
        // Default yeh style is Farsi Yeh (ی, U+06CC); Arabic yeh (ي) accessible via long-press.
        "ش", "س", "ی", "ب", "ل", "ا", "ت", "ن", "م", "ك", "ط",
        // ── Row 3 primaries ────────────────────────────────────────────────
        "ئ", "ء", "ؤ", "ر", "ى", "ة", "و", "ز", "ذ", "د", "ظ",
        // ── Double-tap secondaries (official LSD rules + extended) ─────────
        "ٹ",   // ضض → ٹ
        "پ",   // ثث → پ
        "ھ",   // هه → ھ
        "چ",   // حح → چ
        "ے",   // سس → ے
        "اٰ",  // اا → اٰ
        "گ",   // كك → گ
        "ں",   // طط → ں
        "ڑ",   // رر → ڑ
        "ۃ",   // ةة → ۃ
        "ڈ",   // دد → ڈ
        "ہ",   // ظظ → ہ
    ]

    // MARK: - Layout tests

    func testLSDLayout() {
        assertAccessible(Self.standardLSDCharacters,
                         in: KeyboardLayoutData.defaultLayer,
                         name: "LSD")
    }

    func testArabicStandardLayout() {
        assertAccessible(Self.standardLSDCharacters,
                         in: ArabicStandardLayoutData.defaultLayer,
                         name: "Arabic Standard")
    }

    func testCRULPUrduLayout() {
        assertAccessible(Self.standardLSDCharacters,
                         in: CRULPUrduLayoutData.defaultLayer,
                         name: "CRULP Urdu")
    }

    // MARK: - Helper

    /// Returns every character reachable via tap or double-tap from a layer's
    /// character keys (excludes long-press alternates and other layers).
    func reachable(in layer: KeyboardLayer) -> Set<String> {
        var result = Set<String>()
        for row in layer.rows {
            for key in row where key.type == .character {
                if !key.primary.isEmpty   { result.insert(key.primary) }
                if !key.secondary.isEmpty { result.insert(key.secondary) }
            }
        }
        return result
    }

    private func assertAccessible(
        _ required: Set<String>,
        in layer: KeyboardLayer,
        name: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let missing = required.subtracting(reachable(in: layer))
        guard !missing.isEmpty else { return }
        XCTFail(
            "[\(name)] \(missing.count) character(s) missing from base layer " +
            "(not a primary key or double-tap secondary):\n  " +
            missing.sorted().joined(separator: "  "),
            file: file, line: line
        )
    }
}
