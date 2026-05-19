import Foundation

// Collects every word typed with the LSD keyboard.
// Stored in the App Group container shared with the main app.
// Falls back to the extension's own UserDefaults if the group isn't configured.

final class CorpusLogger {
    static let shared = CorpusLogger()
    private init() {}

    private var pendingWord = ""
    private static let groupID  = "group.com.exordiumnetworks.lsdkeyboard"
    private static let wordsKey = "lsd_corpus_words"

    private let defaults: UserDefaults = {
        UserDefaults(suiteName: "group.com.exordiumnetworks.lsdkeyboard") ?? {
            print("[CorpusLogger] ⚠️ App Group not available — falling back to standard UserDefaults")
            return .standard
        }()
    }()

    // Call on every character inserted via textDocumentProxy.
    func record(_ text: String) {
        for scalar in text.unicodeScalars {
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

    // Flush the current pending word to storage.
    func flush() {
        let word = pendingWord
        pendingWord = ""
        guard !word.isEmpty else { return }
        var words = storedWords
        words.append(word)
        defaults.set(words, forKey: Self.wordsKey)
        defaults.synchronize()
        print("[CorpusLogger] saved "\(word)"  (total: \(words.count) words)")
    }

    var wordCount: Int { storedWords.count }

    // Newline-separated word list suitable for a training corpus.
    func exportText() -> String {
        storedWords.joined(separator: "\n")
    }

    func clear() {
        defaults.removeObject(forKey: Self.wordsKey)
        pendingWord = ""
        print("[CorpusLogger] corpus cleared")
    }

    private var storedWords: [String] {
        defaults.stringArray(forKey: Self.wordsKey) ?? []
    }
}
