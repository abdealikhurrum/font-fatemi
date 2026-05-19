import Foundation

// Collects every word typed with the LSD keyboard.
// Stored in the extension's own UserDefaults (standard).
// Data stays in the extension sandbox; use exportText() + UIPasteboard
// to copy out, or set up an App Group to share with the main app.

final class CorpusLogger {
    static let shared = CorpusLogger()
    private init() {}

    private var pendingWord = ""
    private static let wordsKey = "lsd_corpus_words"
    private static let sessionCountKey = "lsd_corpus_session_count"

    // Call on every character inserted via textDocumentProxy.
    func record(_ text: String) {
        for scalar in text.unicodeScalars {
            let ch = String(scalar)
            switch scalar.value {
            case 0x0020, 0x000A,           // space, newline
                 0x060C, 0x061B, 0x061F,   // Arabic comma, semicolon, question
                 0x06D4,                    // Arabic full stop
                 0x002E, 0x002C:            // ASCII period, comma
                flush()
            default:
                pendingWord.unicodeScalars.append(scalar)
            }
        }
    }

    // Call when backspace is pressed so the pending word stays accurate.
    func recordBackspace() {
        if !pendingWord.isEmpty { pendingWord.removeLast() }
    }

    // Flush whatever is pending (e.g. on keyboard dismiss or explicit trigger).
    func flush() {
        let word = pendingWord
        pendingWord = ""
        guard !word.isEmpty else { return }
        var words = storedWords
        words.append(word)
        UserDefaults.standard.set(words, forKey: Self.wordsKey)
        UserDefaults.standard.set(sessionCount + 1, forKey: Self.sessionCountKey)
    }

    var wordCount: Int { storedWords.count }

    var sessionCount: Int {
        UserDefaults.standard.integer(forKey: Self.sessionCountKey)
    }

    // Newline-separated word list suitable for a training corpus.
    func exportText() -> String {
        storedWords.joined(separator: "\n")
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: Self.wordsKey)
        UserDefaults.standard.removeObject(forKey: Self.sessionCountKey)
        pendingWord = ""
    }

    private var storedWords: [String] {
        UserDefaults.standard.stringArray(forKey: Self.wordsKey) ?? []
    }
}
