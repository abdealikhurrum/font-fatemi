import Foundation

// Collects every word typed with the LSD keyboard.
//
// Storage: JSON file in the App Group container so the main app can read it.
// Falls back to the extension's own Documents folder if the group isn't
// provisioned — containerURL(forSecurityApplicationGroupIdentifier:) returns
// nil rather than a dummy object, unlike UserDefaults(suiteName:).

final class CorpusLogger {
    static let shared = CorpusLogger()
    private init() {}

    private var pendingWord = ""
    private static let groupID   = "group.com.exordiumnetworks.lsdkeyboard"
    private static let fileName  = "lsd_corpus_words.json"

    // Frequency map rebuilt lazily; invalidated whenever the corpus file is written.
    private var frequencyCache: [String: Int]?

    // MARK: - Storage URL

    private lazy var corpusFileURL: URL = {
        if let groupContainer = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Self.groupID) {
            do {
                try FileManager.default.createDirectory(
                    at: groupContainer, withIntermediateDirectories: true)
                let probe = groupContainer.appendingPathComponent(".lsd_probe")
                try Data().write(to: probe, options: .atomic)
                try FileManager.default.removeItem(at: probe)
                let url = groupContainer.appendingPathComponent(Self.fileName)
                print("[CorpusLogger] storage (shared) → \(url.path)")
                return url
            } catch {
                print("[CorpusLogger] ⚠️ App Group container not writable (\(error.localizedDescription)) — falling back to extension Documents")
            }
        } else {
            print("[CorpusLogger] ⚠️ App Group not configured — falling back to extension Documents")
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url  = docs.appendingPathComponent(Self.fileName)
        print("[CorpusLogger] storage (local) → \(url.path)")
        return url
    }()

    // URL callers can pass to UIActivityViewController for file export.
    var exportURL: URL { corpusFileURL }

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
        print("[CorpusLogger] saved \(word)  (total: \(words.count) words)")
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

    // MARK: - Predictions

    /// Top completions for `prefix`, ordered by corpus frequency.
    /// Returns words that start with the prefix (including the prefix itself if
    /// it appears in the corpus as a complete word).
    func suggestions(for prefix: String, limit: Int = 3) -> [String] {
        guard !prefix.isEmpty else { return [] }
        let freq = frequencyMap()
        return freq
            .filter { $0.key.hasPrefix(prefix) }
            .sorted { lhs, rhs in
                lhs.value != rhs.value ? lhs.value > rhs.value : lhs.key.count < rhs.key.count
            }
            .prefix(limit)
            .map { $0.key }
    }

    // MARK: - File I/O

    private func load() -> [String] {
        guard let data = try? Data(contentsOf: corpusFileURL),
              let words = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return words
    }

    private func save(_ words: [String]) {
        frequencyCache = nil   // invalidate so next prediction call rebuilds
        guard let data = try? JSONEncoder().encode(words) else { return }
        do {
            try data.write(to: corpusFileURL, options: .atomic)
        } catch {
            print("[CorpusLogger] ⚠️ write failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Private helpers

    private func frequencyMap() -> [String: Int] {
        if let cached = frequencyCache { return cached }
        var freq: [String: Int] = [:]
        for word in load() { freq[word, default: 0] += 1 }
        frequencyCache = freq
        return freq
    }
}
