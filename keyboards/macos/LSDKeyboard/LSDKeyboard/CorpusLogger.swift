import Foundation

// Tracks every word typed with the LSD keyboard plus bigrams and correction signals.
// Storage: ~/Library/Application Support/LSDKeyboard/lsd_corpus_words.json
//
// Schema is intentionally compatible with the iOS CorpusLogger so JSON files
// from all platforms can be merged without transformation. The iOS fields
// `offsets` and `snapshots` are omitted here (not applicable on a physical
// keyboard); JSONDecoder fills them with their default empty-dict values when
// reading macOS files on iOS, and ignores them in the other direction.

final class CorpusLogger {
    static let shared = CorpusLogger()
    private init() {}

    private var pendingWord  = ""
    private var previousWord = ""

    // For correction detection: backspace within 0.6 s of a character insertion.
    private var lastInsertedChar = ""
    private var lastInsertTime   = Date.distantPast

    private var memCache:     CorpusData?
    private var unigramCache: [String: Int]?

    // MARK: - Storage

    private lazy var corpusFileURL: URL = {
        let support = FileManager.default.urls(for: .applicationSupportDirectory,
                                               in: .userDomainMask).first!
        let dir = support.appendingPathComponent("LSDKeyboard")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("lsd_corpus_words.json")
        print("[CorpusLogger] storage → \(url.path)")
        return url
    }()

    // MARK: - Recording

    /// Call for every string the IME inserts into the document.
    func record(_ text: String) {
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0020, 0x000A,            // space, newline
                 0x060C, 0x061B, 0x061F,    // ، ؛ ؟
                 0x06D4,                    // ۔
                 0x002E, 0x002C:            // . ,
                flush()
            default:
                pendingWord.unicodeScalars.append(scalar)
            }
        }
        lastInsertedChar = text
        lastInsertTime   = Date()
    }

    /// Call when the IME sees a backspace key event.
    func recordBackspace() {
        if !lastInsertedChar.isEmpty,
           Date().timeIntervalSince(lastInsertTime) < 0.6 {
            var data = loaded()
            data.corrections[lastInsertedChar, default: 0] += 1
            save(data)
        }
        lastInsertedChar = ""
        if !pendingWord.isEmpty { pendingWord.removeLast() }
    }

    /// Flush the current partial word to disk (call on IME deactivation).
    func flush() {
        let word = pendingWord
        pendingWord = ""
        guard !word.isEmpty else { return }

        var data = loaded()
        data.words.append(word)
        if !previousWord.isEmpty {
            data.bigrams[previousWord, default: [:]][word, default: 0] += 1
        }
        previousWord = word
        unigramCache = nil
        save(data)
        print("[CorpusLogger] saved "\(word)"  (total: \(data.words.count) words)")
    }

    func resetPending() {
        pendingWord  = ""
        previousWord = ""
    }

    // MARK: - Predictions (mirrors iOS suggestions API)

    var wordCount: Int { loaded().words.count }

    func suggestions(for prefix: String, after previous: String = "", limit: Int = 3) -> [String] {
        guard !prefix.isEmpty else { return [] }
        let data       = loaded()
        let unigrams   = buildUnigramFreq(data)
        let bigramNext = data.bigrams[previous] ?? [:]
        return unigrams.keys
            .filter  { $0.hasPrefix(prefix) }
            .sorted  {
                let a = (bigramNext[$0] ?? 0) * 3 + (unigrams[$0] ?? 0)
                let b = (bigramNext[$1] ?? 0) * 3 + (unigrams[$1] ?? 0)
                return a != b ? a > b : $0.count < $1.count
            }
            .prefix(limit).map { $0 }
    }

    // MARK: - Export / management

    func exportText() -> String { loaded().words.joined(separator: "\n") }

    func clear() {
        memCache     = CorpusData()
        unigramCache = nil
        pendingWord  = ""
        previousWord = ""
        writeToDisk(CorpusData())
        print("[CorpusLogger] corpus cleared")
    }

    // MARK: - I/O

    private func loaded() -> CorpusData {
        if let c = memCache { return c }
        let data = loadFromDisk(); memCache = data; return data
    }

    private func save(_ data: CorpusData) {
        memCache = data; writeToDisk(data)
    }

    private func loadFromDisk() -> CorpusData {
        guard let raw = try? Data(contentsOf: corpusFileURL) else { return CorpusData() }
        if let data = try? JSONDecoder().decode(CorpusData.self, from: raw) { return data }
        // Migrate legacy flat [String] word list written by earlier builds.
        if let words = try? JSONDecoder().decode([String].self, from: raw) {
            var m = CorpusData(); m.words = words; writeToDisk(m); return m
        }
        return CorpusData()
    }

    private func writeToDisk(_ data: CorpusData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        do    { try encoded.write(to: corpusFileURL, options: .atomic) }
        catch { print("[CorpusLogger] ⚠️ write failed: \(error.localizedDescription)") }
    }

    private func buildUnigramFreq(_ data: CorpusData) -> [String: Int] {
        if let f = unigramCache { return f }
        var freq = [String: Int]()
        for w in data.words { freq[w, default: 0] += 1 }
        unigramCache = freq
        return freq
    }
}

// MARK: - Data model

// Schema-compatible with iOS CorpusData. Fields present here are a subset;
// the missing `offsets` and `snapshots` keys decode as [:] on iOS (their defaults).
struct CorpusData: Codable {
    var words:       [String]                = []
    var bigrams:     [String: [String: Int]] = [:]
    var corrections: [String: Int]           = [:]
}
