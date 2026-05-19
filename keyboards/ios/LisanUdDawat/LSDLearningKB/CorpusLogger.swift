import Foundation

// Collects every word typed with the LSD keyboard.
//
// Storage: JSON file in the App Group container so the main app can read it.
// Falls back to the extension's own Documents folder if the group isn't
// provisioned — containerURL(forSecurityApplicationGroupIdentifier:) returns
// nil rather than a dummy object, unlike UserDefaults(suiteName:).

final class CorpusLogger {
    static let shared = CorpusLogger()
    private init() {
        print("[CorpusLogger] storage → \(corpusFileURL.path)")
    }

    private var pendingWord = ""
    private static let groupID   = "group.com.exordiumnetworks.lsdkeyboard"
    private static let fileName  = "lsd_corpus_words.json"

    // MARK: - Storage URL

    private lazy var corpusFileURL: URL = {
        if let shared = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupID) {
            return shared.appendingPathComponent(Self.fileName)
        }
        print("[CorpusLogger] ⚠️ App Group not available — using extension Documents folder")
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(Self.fileName)
    }()

    // MARK: - Public API

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

    func recordBackspace() {
        if !pendingWord.isEmpty { pendingWord.removeLast() }
    }

    func resetPending() {
        pendingWord = ""
    }

    func flush() {
        let word = pendingWord
        pendingWord = ""
        guard !word.isEmpty else { return }
        var words = load()
        words.append(word)
        save(words)
        print("[CorpusLogger] saved "\(word)"  (total: \(words.count) words)")
    }

    var wordCount: Int { load().count }

    func exportText() -> String {
        load().joined(separator: "\n")
    }

    func clear() {
        save([])
        pendingWord = ""
        print("[CorpusLogger] corpus cleared")
    }

    // MARK: - File I/O

    private func load() -> [String] {
        guard let data = try? Data(contentsOf: corpusFileURL),
              let words = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return words
    }

    private func save(_ words: [String]) {
        guard let data = try? JSONEncoder().encode(words) else { return }
        do {
            try data.write(to: corpusFileURL, options: .atomic)
        } catch {
            print("[CorpusLogger] ⚠️ write failed: \(error.localizedDescription)")
        }
    }
}
