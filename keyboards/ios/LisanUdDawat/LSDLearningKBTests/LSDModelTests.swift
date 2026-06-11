// LSDModelTests.swift
//
// Pins the Swift engine against known rows of the bundled lsd-model.sqlite
// (mirrors lsd-corpus/pipeline/predict.py reference behavior per model.md).

import XCTest

final class LSDModelTests: XCTestCase {

    let model = LSDModel.shared

    func testModelOpens() {
        XCTAssertTrue(model.isAvailable, "bundled lsd-model.sqlite should open")
    }

    func testCompletionRankedByFrequency() {
        let completions = model.completions(of: "چھ", limit: 3)
        XCTAssertEqual(completions.first, "چھے")   // rank 14, the copula
    }

    func testNextWordAgreement() {
        // Pronoun agreement bigram baked in at rank 5: هميں -> 1pl futures
        XCTAssertTrue(model.nextWords(after: "هميں", limit: 10).contains("كريسوں"))
    }

    func testCliticAnalysis() {
        XCTAssertTrue(model.isValidForm("چھے"))         // shipped word
        XCTAssertTrue(model.isValidForm("وچھے"))        // proclitic و + stem
        XCTAssertFalse(model.contains("وچھے"))          // ...not stored as a word
    }

    func testParadigmCorrection() {
        // Categorical error: perfective yeh after plain consonant
        XCTAssertFalse(model.isValidForm("بوليو"))
        XCTAssertTrue(model.corrections(for: "بوليو", limit: 3).contains("بولو"))
    }

    func testVariantSuggestOnly() {
        XCTAssertEqual(model.variants(of: "كريسو"), ["كريسوں"])
        // A valid word never produces corrections (suggest, don't correct)
        XCTAssertEqual(model.corrections(for: "كريسو"), [])
    }

    func testTransliteration() {
        // Skeleton reduction (mirrors pipeline/translit.py)
        XCTAssertEqual(Transliterator.latinSkeleton("sidna"), "sdn")
        XCTAssertEqual(Transliterator.latinSkeleton("khushi"), "x$")    // kh + sh digraphs
        XCTAssertEqual(Transliterator.latinSkeleton("topi"), "tp")
        // Dictionary-grounded lookup, frequency + vowel-similarity ranked
        XCTAssertEqual(Transliterator.suggestions(for: "sidna").first, "سيدنا")
        XCTAssertEqual(Transliterator.suggestions(for: "topi").first, "ٹوپي")
        XCTAssertEqual(Transliterator.suggestions(for: "maa").first, "ماں")
        XCTAssertEqual(Transliterator.suggestions(for: "khushi").first, "خوشي")
        // Closed-class function words map directly
        XCTAssertEqual(Transliterator.suggestions(for: "tame"), ["تميں"])
        // Empty input -> no candidates
        XCTAssertEqual(Transliterator.suggestions(for: ""), [])
    }

    func testHonorificsReversible() {
        // Two-token abbreviation: typed "ع م" after a name
        let twoToken = model.honorifics(prev1: "م", prev2: "ع")
        XCTAssertEqual(twoToken.first?.typed, "ع م")
        XCTAssertEqual(twoToken.first?.sign, "\u{0611}")            // ؑ
        // Single-token abbreviations
        XCTAssertEqual(model.honorifics(prev1: "رض").first?.sign, "\u{0613}")  // ؓ
        XCTAssertEqual(model.honorifics(prev1: "صلع").first?.sign, "\u{FD46}") // ﵆
        XCTAssertEqual(model.honorifics(prev1: "قس").first?.sign, "\u{FD4B}")  // ﵋
        // Reverse mapping restores the typed text
        XCTAssertEqual(model.honorificSource(of: "\u{0611}"), ["ع م"])
    }
}
