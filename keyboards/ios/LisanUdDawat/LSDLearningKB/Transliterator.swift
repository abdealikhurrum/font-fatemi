import Foundation

// Latin -> Lisan ud-Dawat transliteration (EXPERIMENTAL).
//
// Client-side mirror of lsd-corpus/pipeline/translit.py (v0): Latin->Arabic is
// many-to-many and ambiguous, so both the Latin input and every LD word reduce
// to a strong-consonant skeleton (weak letters/vowels dropped). The model's
// `translit` table holds the precomputed skeleton index (incl. the ں-dropped
// and ض→ز alternates, with lexicon-boosted ranks); this class does the
// per-keystroke part: skeleton the input, look it up, and rerank candidates by
// vowel-similarity against rough romanizations blended with frequency.
//
//   sidna -> sdn -> سيدنا      ibadat -> bdt -> عبادة
//   topi  -> tp  -> ٹوپي       maa    -> m   -> ماں
enum Transliterator {

    // MARK: - Latin -> skeleton (digraphs first; aspiration h absorbed)

    private static let latinDigraphs: [(String, String)] = [
        ("sh", "$"), ("ch", "c"), ("kh", "x"), ("gh", "g"), ("th", "t"),
        ("dh", "d"), ("bh", "b"), ("ph", "f"), ("jh", "j"), ("zh", "j"),
        ("ck", "k"), ("qu", "k"),
    ]
    private static let latinSingles: [Character: String] = [
        "b": "b", "p": "p", "f": "f", "m": "m", "n": "n", "l": "l",
        "t": "t", "s": "s", "c": "k", "j": "j", "d": "d",
        "z": "z", "r": "r", "k": "k", "q": "k", "g": "g", "x": "x",
    ]

    static func latinSkeleton(_ text: String) -> String {
        let chars = Array(text.lowercased())
        var out = ""
        var i = 0
        while i < chars.count {
            if i + 1 < chars.count {
                let two = String(chars[i...i+1])
                if let sym = latinDigraphs.first(where: { $0.0 == two })?.1 {
                    out += sym; i += 2; continue
                }
            }
            if let sym = latinSingles[chars[i]] { out += sym }
            // else weak/unknown -> drop
            i += 1
        }
        return out
    }

    // MARK: - Closed-class function words (mapped directly)

    // Pronouns/particles carry unwritten nasalization that defeats fuzzy
    // matching, so they bypass the skeleton lookup entirely.
    private static let direct: [String: String] = [
        "tame": "تميں", "hame": "هميں", "ame": "اميں", "mein": "ميں", "me": "ميں",
        "tu": "تو", "tane": "تنے", "mane": "منے", "ene": "انے",
    ]

    // MARK: - Rough romanization (vowel-aware reranking)

    // Letters with several Latin realizations expand to VARIANTS so each LD
    // stratum romanizes the way people actually type it (faiz, asr, jannat).
    // Keyboard-side additions vs the pipeline map: ں may be unwritten (maa ->
    // ماں), ا carries any short vowel or doubles (imam, salaam), ي adds "ee".
    private static let roughVariants: [Character: [String]] = [
        "ع": ["a", "i", "u", "'", ""], "ء": ["", "a", "'"],
        "ح": ["h", ""], "ه": ["h", ""], "ہ": ["h", ""],
        "ي": ["i", "e", "y", "ai", "ay", "ee"], "ی": ["i", "e", "y"], "ے": ["e", "ay"],
        "و": ["o", "u", "v", "w", "oo"], "ا": ["a", "aa", "i", "u", ""],
        "آ": ["a", "aa"], "ى": ["a", "i"],
        "ض": ["z", "d"], "ظ": ["z"], "ذ": ["z", "d"], "ث": ["s", "th"],
        "ة": ["a", "t", ""], "ق": ["q", "k"], "ں": ["n", ""],
    ]
    // Single rough value for everything else (strong consonants + weak rest).
    private static let rough: [Character: String] = [
        "ب": "b", "پ": "p", "ف": "f", "م": "m", "ن": "n", "ل": "l",
        "ت": "t", "ط": "t", "ٹ": "t",
        "س": "s", "ص": "s", "ش": "sh", "ج": "j", "چ": "ch",
        "د": "d", "ڈ": "d", "ز": "z", "ر": "r", "ڑ": "r",
        "ك": "k", "ک": "k", "گ": "g", "غ": "g", "خ": "kh",
        "أ": "a", "إ": "a", "ھ": "h",
    ]

    /// Plausible romanizations of an LD word, expanding multi-valued letters.
    private static func romanVariants(of word: String, cap: Int = 32) -> [String] {
        var out = [""]
        for c in word {
            if let opts = roughVariants[c] {
                out = out.flatMap { v in opts.map { v + $0 } }
            } else {
                let base = rough[c] ?? ""
                out = out.map { $0 + base }
            }
            if out.count > cap { out = Array(out.prefix(cap)) }
        }
        return Array(Set(out))
    }

    /// Levenshtein ratio in [0, 1] — the portable stand-in for Python's
    /// SequenceMatcher.ratio() used by the reference implementation.
    private static func similarity(_ a: String, _ b: String) -> Double {
        let x = Array(a), y = Array(b)
        if x.isEmpty && y.isEmpty { return 1 }
        var prev = Array(0...y.count)
        for i in 1...max(x.count, 1) where !x.isEmpty {
            var cur = [i] + Array(repeating: 0, count: y.count)
            for j in 1...y.count {
                cur[j] = min(prev[j] + 1, cur[j - 1] + 1,
                             prev[j - 1] + (x[i - 1] == y[j - 1] ? 0 : 1))
            }
            prev = cur
        }
        return 1 - Double(prev[y.count]) / Double(max(x.count, y.count))
    }

    // MARK: - Suggestions

    /// Ranked LD candidates for one Latin word. Empty when the model (or its
    /// translit table) is unavailable or nothing matches.
    static func suggestions(for latin: String, limit: Int = 3) -> [String] {
        let low = latin.lowercased()
        guard !low.isEmpty else { return [] }
        if let word = direct[low] { return [word] }
        // 'kh' is ambiguous — خ (fricative: خوشي) vs کھ (aspirated: دیکھو) — in
        // different skeleton buckets; search BOTH, let the dictionary decide.
        var skeletons = Set([latinSkeleton(low)])
        if low.contains("kh") {
            skeletons.insert(latinSkeleton(low.replacingOccurrences(of: "kh", with: "k")))
        }
        var best: [String: Int] = [:]
        for sk in skeletons {
            for (word, rank) in LSDModel.shared.translitCandidates(skeleton: sk) {
                best[word] = max(best[word] ?? 0, rank)
            }
        }
        guard !best.isEmpty else { return [] }
        let maxRank = Double(max(LSDModel.shared.translitMaxRank, 1))
        return best
            .map { word, rank -> (Double, String) in
                let sim = romanVariants(of: word).map { similarity(low, $0) }.max() ?? 0
                return (0.8 * sim + 0.2 * Double(rank) / maxRank, word)
            }
            // Ties sort by word DESCENDING — matches the reference's
            // sorted(..., reverse=True), which puts ماں before ما for "maa".
            .sorted { $0.0 != $1.0 ? $0.0 > $1.0 : $0.1 > $1.1 }
            .prefix(limit)
            .map { $0.1 }
    }
}
