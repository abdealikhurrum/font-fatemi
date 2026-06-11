import Foundation
import SQLite3

// Read-only engine over the bundled lsd-model.sqlite (the generic, filtered,
// neutralized model built by the lsd-corpus pipeline). Mirrors the reference
// implementation spec in lsd-corpus/pipeline/model.md:
//
//   words(word, rank)              completion + correction ranking
//   ngrams(prev, next, rank)       next-word with trigram→bigram backoff
//   rules(kind, frm, dst)          heh/yeh/double-press + paradigm (correct),
//                                  variant + honorific (suggest-only)
//   paradigms(lemma, stem, key, cell, form)   conjugation panels (future use)
//
// All queries are tiny indexed lookups; safe to run per keystroke.
final class LSDModel {

    static let shared = LSDModel()

    private var db: OpaquePointer?

    var isAvailable: Bool { db != nil }

    private init() {
        guard let url = Bundle(for: LSDModel.self).url(forResource: "lsd-model", withExtension: "sqlite") else { return }
        var handle: OpaquePointer?
        // Immutable: the bundle is read-only; avoids journal/WAL file creation
        // attempts inside the signed extension bundle.
        let uri = "file:\(url.path)?immutable=1"
        if sqlite3_open_v2(uri, &handle, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK {
            db = handle
        } else {
            sqlite3_close(handle)
        }
    }

    deinit { sqlite3_close(db) }

    // MARK: - Core query helper

    private func query(_ sql: String, _ args: [String], limit: Int = 50) -> [[String]] {
        guard let db else { return [] }
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        for (i, arg) in args.enumerated() {
            sqlite3_bind_text(stmt, Int32(i + 1), arg, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
        }
        var rows: [[String]] = []
        while sqlite3_step(stmt) == SQLITE_ROW && rows.count < limit {
            var row: [String] = []
            for c in 0..<sqlite3_column_count(stmt) {
                row.append(sqlite3_column_text(stmt, c).map { String(cString: $0) } ?? "")
            }
            rows.append(row)
        }
        return rows
    }

    // MARK: - Words

    func contains(_ word: String) -> Bool {
        !query("SELECT 1 FROM words WHERE word = ?", [word], limit: 1).isEmpty
    }

    func rank(of word: String) -> Int {
        Int(query("SELECT rank FROM words WHERE word = ?", [word], limit: 1).first?.first ?? "0") ?? 0
    }

    /// Batched rank lookup — one indexed query per 500 candidates instead of
    /// one per candidate (the edit-distance-1 set is ~10^3 strings).
    private func ranks(of words: [String]) -> [String: Int] {
        var out: [String: Int] = [:]
        var i = 0
        while i < words.count {
            let chunk = Array(words[i..<min(i + 500, words.count)])
            let marks = Array(repeating: "?", count: chunk.count).joined(separator: ",")
            for row in query("SELECT word, rank FROM words WHERE word IN (\(marks))", chunk, limit: 500) {
                out[row[0]] = Int(row[1]) ?? 0
            }
            i += 500
        }
        return out
    }

    /// Prefix completion, most frequent first. Range scan on the PK index.
    func completions(of prefix: String, limit: Int = 3) -> [String] {
        guard !prefix.isEmpty else { return [] }
        return query(
            "SELECT word FROM words WHERE word >= ? AND word < ? ORDER BY rank DESC, word LIMIT \(limit)",
            [prefix, prefix + "\u{FFFF}"]
        ).map { $0[0] }
    }

    // MARK: - Next word (trigram → bigram backoff)

    func nextWords(after prev1: String, prev2: String? = nil, limit: Int = 3) -> [String] {
        var out: [String] = []
        var contexts: [String] = []
        if let prev2, !prev2.isEmpty { contexts.append("\(prev2) \(prev1)") }
        contexts.append(prev1)
        for ctx in contexts {
            for row in query("SELECT next FROM ngrams WHERE prev = ? ORDER BY rank DESC LIMIT \(limit)", [ctx]) {
                if !out.contains(row[0]) { out.append(row[0]) }
            }
            if out.count >= limit { break }
        }
        return Array(out.prefix(limit))
    }

    // MARK: - Clitic analysis (model.md: a cliticized valid stem is not an error)

    // Longest-first, as specified.
    private static let proclitics = ["وبال", "فبال", "بال", "كال", "فال", "وال",
                                     "لل", "وب", "فب", "ول", "فل", "بل", "كل", "ال",
                                     "و", "ف", "ب", "ك", "ل"]
    private static let enclitics = ["هما", "كما", "هم", "هن", "كم", "كن", "ها",
                                    "نا", "ني", "ه", "ك", "ي"]

    /// True when `word` is a shipped word, or proclitic + stem + enclitic
    /// around a shipped stem of length >= 2.
    func isValidForm(_ word: String) -> Bool {
        if contains(word) { return true }
        var stems = [word]
        if let p = Self.proclitics.first(where: { word.hasPrefix($0) && word.count > $0.count }) {
            stems.append(String(word.dropFirst(p.count)))
        }
        for stem in stems {
            if stem != word && stem.count >= 2 && contains(stem) { return true }
            if let e = Self.enclitics.first(where: { stem.hasSuffix($0) && stem.count > $0.count }) {
                let residue = String(stem.dropLast(e.count))
                if residue.count >= 2 && contains(residue) { return true }
            }
        }
        return false
    }

    // MARK: - Corrections (rules + edit-distance-1, ranked by word rank)

    // Letters reachable from the LSD layouts; used for edit-1 candidate generation.
    private static let alphabet = Array("ابتثجحخدذرزسشصضطظعغفقكلمنهويءآأؤئىةپچڈڑژگںھہيےٹ")

    /// Correction candidates for a word that is NOT a valid form.
    /// kind in (heh, yeh, double-press): substring substitution, both directions.
    /// kind = paradigm: categorical errors, exact frm -> dst.
    func corrections(for word: String, limit: Int = 3) -> [String] {
        guard !word.isEmpty, isAvailable, !isValidForm(word) else { return [] }
        var candidates = Set<String>()

        // Exact paradigm corrections (بوليو -> بولو)
        for row in query("SELECT dst FROM rules WHERE kind = 'paradigm' AND frm = ?", [word]) {
            candidates.insert(row[0])
        }
        // Confusion-rule substitutions, both directions, each occurrence
        for row in query("SELECT frm, dst FROM rules WHERE kind IN ('heh','yeh','double-press')", []) {
            for (a, b) in [(row[0], row[1]), (row[1], row[0])] where word.contains(a) {
                candidates.insert(word.replacingOccurrences(of: a, with: b))
            }
        }
        // Edit distance 1
        let chars = Array(word)
        for i in 0..<chars.count {                       // deletions
            candidates.insert(String(chars[0..<i] + chars[(i+1)...]))
        }
        for i in 0..<(chars.count - 1) {                 // transpositions
            var t = chars; t.swapAt(i, i + 1); candidates.insert(String(t))
        }
        for i in 0...chars.count {                       // insertions
            for ch in Self.alphabet {
                candidates.insert(String(chars[0..<i]) + String(ch) + String(chars[i...]))
            }
        }
        for i in 0..<chars.count {                       // substitutions
            for ch in Self.alphabet where ch != chars[i] {
                var s = chars; s[i] = ch; candidates.insert(String(s))
            }
        }
        candidates.remove(word)

        let ranked = ranks(of: Array(candidates))
        return ranked
            .sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }
            .prefix(limit)
            .map { $0.key }
    }

    // MARK: - Suggest-only rules

    /// Legitimate alternate spellings (كريسو -> كريسوں). Never auto-applied.
    func variants(of word: String) -> [String] {
        query("SELECT dst FROM rules WHERE kind = 'variant' AND frm = ?", [word]).map { $0[0] }
    }

    /// Honorific signs for a typed abbreviation: the last token, or the last
    /// two tokens joined with a space. Suggest-only and reversible — the sign
    /// replaces the abbreviation as its own token; the name is never rewritten.
    func honorifics(prev1: String, prev2: String? = nil) -> [(typed: String, sign: String)] {
        var out: [(String, String)] = []
        var typedForms = [prev1]
        if let prev2, !prev2.isEmpty { typedForms.append("\(prev2) \(prev1)") }
        for typed in typedForms {
            for row in query("SELECT dst FROM rules WHERE kind = 'honorific' AND frm = ?", [typed]) {
                out.append((typed, row[0]))
            }
        }
        return out
    }

    /// Reverse lookup: the typed abbreviation(s) a sign came from.
    func honorificSource(of sign: String) -> [String] {
        query("SELECT frm FROM rules WHERE kind = 'honorific' AND dst = ?", [sign]).map { $0[0] }
    }

    // MARK: - Transliteration (translit table; see Transliterator)

    /// Candidates sharing a Latin strong-consonant skeleton, by rank. Empty
    /// when the bundled model predates the translit table.
    func translitCandidates(skeleton: String, limit: Int = 500) -> [(word: String, rank: Int)] {
        guard !skeleton.isEmpty else { return [] }
        return query(
            "SELECT word, rank FROM translit WHERE skeleton = ? ORDER BY rank DESC LIMIT \(limit)",
            [skeleton], limit: limit
        ).map { ($0[0], Int($0[1]) ?? 0) }
    }

    private(set) lazy var translitMaxRank: Int =
        Int(query("SELECT MAX(rank) FROM translit", [], limit: 1).first?.first ?? "1") ?? 1
}
