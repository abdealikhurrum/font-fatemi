import Foundation

// Tracks every word typed with the LSD keyboard plus three behavioural signals:
//   bigrams     — which word follows which (improves next-word predictions)
//   offsets     — per-key touch drift from key centre (future hit-target tuning)
//   corrections — characters backspaced within 0.6 s of insertion (mistype signal)
//
// Storage: CorpusData JSON in the App Group container so the main app can read it.
// Falls back to the extension's own Documents folder when the group isn't provisioned.
//
// Touch offsets accumulate in memory and are flushed to disk only in persistOffsets()
// to avoid a disk write on every keypress.

final class CorpusLogger {
    static let shared = CorpusLogger()
    private init() {}

    private var pendingWord  = ""
    private var previousWord = ""   // last fully-flushed word, for bigram recording

    private static let groupID  = "group.com.exordiumnetworks.lsdkeyboard"
    private static let fileName = "lsd_corpus_words.json"

    // In-memory corpus — loaded lazily, written on word/correction events
    private var memCache: CorpusData?
    // Touch offsets accumulate here; written only when persistOffsets() is called
    private var offsetsDirty = false

    // Derived frequency tables; invalidated whenever memCache is replaced
    private var unigramFreq: [String: Int]?
    private var bigramFreq:  [String: [String: Int]]?

    // MARK: - Storage URL

    private lazy var corpusFileURL: URL = {
        if let group = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: Self.groupID) {
            do {
                try FileManager.default.createDirectory(
                    at: group, withIntermediateDirectories: true)
                let probe = group.appendingPathComponent(".lsd_probe")
                try Data().write(to: probe, options: .atomic)
                try FileManager.default.removeItem(at: probe)
                let url = group.appendingPathComponent(Self.fileName)
                print("[CorpusLogger] storage (shared) → \(url.path)")
                return url
            } catch {
                print("[CorpusLogger] ⚠️ App Group not writable (\(error.localizedDescription)) — using extension Documents")
            }
        } else {
            print("[CorpusLogger] ⚠️ App Group not configured — using extension Documents")
        }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url  = docs.appendingPathComponent(Self.fileName)
        print("[CorpusLogger] storage (local) → \(url.path)")
        return url
    }()

    // MARK: - Word recording

    func record(_ text: String) {
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0020, 0x000A,
                 0x060C, 0x061B, 0x061F,
                 0x06D4,
                 0x002E, 0x002C:
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
        pendingWord  = ""
        previousWord = ""
    }

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
        save(data)
        print("[CorpusLogger] saved \(word)  (total: \(data.words.count) words)")
    }

    // MARK: - Touch offsets (batched — call persistOffsets() on keyboard dismiss)

    func recordTouchOffset(for key: String, dx: Float, dy: Float) {
        var data = loaded()
        data.offsets[key, default: OffsetStats()].record(dx, dy)
        memCache     = data   // in-memory only — skip disk write
        offsetsDirty = true
        unigramFreq  = nil
        bigramFreq   = nil
    }

    func persistOffsets() {
        guard offsetsDirty, let data = memCache else { return }
        offsetsDirty = false
        writeToDisk(data)
    }

    // MARK: - Correction tracking

    func recordCorrection(for char: String) {
        guard !char.isEmpty else { return }
        var data = loaded()
        data.corrections[char, default: 0] += 1
        save(data)
    }

    // MARK: - Predictions

    var wordCount: Int { loaded().words.count }

    /// Top completions for `prefix`, blending bigram context with unigram frequency.
    /// Bigram matches are weighted 3× so contextual completions rise to the top.
    func suggestions(for prefix: String, after previous: String = "", limit: Int = 3) -> [String] {
        guard !prefix.isEmpty else { return [] }
        let data       = loaded()
        let unigrams   = buildUnigramFreq(data)
        let bigramNext = buildBigramFreq(data)[previous] ?? [:]

        return unigrams.keys
            .filter { $0.hasPrefix(prefix) }
            .sorted { a, b in
                let scoreA = (bigramNext[a] ?? 0) * 3 + (unigrams[a] ?? 0)
                let scoreB = (bigramNext[b] ?? 0) * 3 + (unigrams[b] ?? 0)
                if scoreA != scoreB { return scoreA > scoreB }
                return a.count < b.count
            }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Corpus management

    func clear() {
        let empty = CorpusData()
        memCache     = empty
        offsetsDirty = false
        unigramFreq  = nil
        bigramFreq   = nil
        pendingWord  = ""
        previousWord = ""
        writeToDisk(empty)
        print("[CorpusLogger] corpus cleared")
    }

    func exportText() -> String { loaded().words.joined(separator: "\n") }

    // MARK: - I/O

    private func loaded() -> CorpusData {
        if let c = memCache { return c }
        let data = loadFromDisk()
        memCache = data
        return data
    }

    private func save(_ data: CorpusData) {
        memCache    = data
        unigramFreq = nil
        bigramFreq  = nil
        writeToDisk(data)
    }

    private func loadFromDisk() -> CorpusData {
        guard let raw = try? Data(contentsOf: corpusFileURL) else { return CorpusData() }
        if let data = try? JSONDecoder().decode(CorpusData.self, from: raw) { return data }
        // Migrate legacy flat [String] format written by earlier builds
        if let words = try? JSONDecoder().decode([String].self, from: raw) {
            print("[CorpusLogger] migrating legacy word list (\(words.count) words)")
            var migrated = CorpusData()
            migrated.words = words
            writeToDisk(migrated)
            return migrated
        }
        return CorpusData()
    }

    private func writeToDisk(_ data: CorpusData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        do { try encoded.write(to: corpusFileURL, options: .atomic) }
        catch { print("[CorpusLogger] ⚠️ write failed: \(error.localizedDescription)") }
    }

    // MARK: - Frequency helpers (lazily cached)

    private func buildUnigramFreq(_ data: CorpusData) -> [String: Int] {
        if let f = unigramFreq { return f }
        var freq = [String: Int]()
        for w in data.words { freq[w, default: 0] += 1 }
        unigramFreq = freq
        return freq
    }

    private func buildBigramFreq(_ data: CorpusData) -> [String: [String: Int]] {
        if let f = bigramFreq { return f }
        bigramFreq = data.bigrams
        return data.bigrams
    }
}

// MARK: - Data model

struct CorpusData: Codable {
    var words:       [String]                = []
    var bigrams:     [String: [String: Int]] = [:]  // prev → next → count
    var offsets:     [String: OffsetStats]   = [:]  // key primary → running mean offset
    var corrections: [String: Int]           = [:]  // char → immediate-backspace count
}

struct OffsetStats: Codable {
    var count:  Int   = 0
    var meanDx: Float = 0
    var meanDy: Float = 0

    mutating func record(_ dx: Float, _ dy: Float) {
        count += 1
        let n  = Float(count)
        meanDx += (dx - meanDx) / n   // Welford online mean
        meanDy += (dy - meanDy) / n
    }
}
