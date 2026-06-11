package com.exordiumnetworks.ligacheh

// Latin -> Lisan ud-Dawat transliteration (EXPERIMENTAL).
//
// Direct port of the iOS LSDLearningKB/Transliterator.swift, itself a client-
// side mirror of lsd-corpus/pipeline/translit.py (v0): Latin->Arabic is
// many-to-many and ambiguous, so both the Latin input and every LD word reduce
// to a strong-consonant skeleton (weak letters/vowels dropped). The model's
// `translit` table holds the precomputed skeleton index (incl. the ں-dropped
// and ض→ز alternates, with lexicon-boosted ranks); this object does the
// per-keystroke part: skeleton the input, look it up, and rerank candidates by
// vowel-similarity against rough romanizations blended with frequency.
//
//   sidna -> sdn -> سيدنا      ibadat -> bdt -> عبادة
//   topi  -> tp  -> ٹوپي       maa    -> m   -> ماں
object Transliterator {

    // ── Latin -> skeleton (digraphs first; aspiration h absorbed) ────────

    private val latinDigraphs = listOf(
        "sh" to "$", "ch" to "c", "kh" to "x", "gh" to "g", "th" to "t",
        "dh" to "d", "bh" to "b", "ph" to "f", "jh" to "j", "zh" to "j",
        "ck" to "k", "qu" to "k",
    )
    private val latinSingles = mapOf(
        'b' to "b", 'p' to "p", 'f' to "f", 'm' to "m", 'n' to "n", 'l' to "l",
        't' to "t", 's' to "s", 'c' to "k", 'j' to "j", 'd' to "d",
        'z' to "z", 'r' to "r", 'k' to "k", 'q' to "k", 'g' to "g", 'x' to "x",
    )

    fun latinSkeleton(text: String): String {
        val t = text.lowercase()
        val out = StringBuilder()
        var i = 0
        while (i < t.length) {
            if (i + 1 < t.length) {
                val two = t.substring(i, i + 2)
                val sym = latinDigraphs.firstOrNull { it.first == two }?.second
                if (sym != null) { out.append(sym); i += 2; continue }
            }
            latinSingles[t[i]]?.let { out.append(it) }
            // else weak/unknown -> drop
            i += 1
        }
        return out.toString()
    }

    // ── Closed-class function words (mapped directly) ─────────────────────

    // Pronouns/particles carry unwritten nasalization that defeats fuzzy
    // matching, so they bypass the skeleton lookup entirely.
    private val direct = mapOf(
        "tame" to "تميں", "hame" to "هميں", "ame" to "اميں", "mein" to "ميں",
        "me" to "ميں", "tu" to "تو", "tane" to "تنے", "mane" to "منے", "ene" to "انے",
    )

    // ── Rough romanization (vowel-aware reranking) ────────────────────────

    // Letters with several Latin realizations expand to VARIANTS so each LD
    // stratum romanizes the way people actually type it (faiz, asr, jannat).
    // Keyboard-side additions vs the pipeline map: ں may be unwritten (maa ->
    // ماں), ا carries any short vowel or doubles (imam, salaam), ي adds "ee".
    private val roughVariants = mapOf(
        'ع' to listOf("a", "i", "u", "'", ""), 'ء' to listOf("", "a", "'"),
        'ح' to listOf("h", ""), 'ه' to listOf("h", ""), 'ہ' to listOf("h", ""),
        'ي' to listOf("i", "e", "y", "ai", "ay", "ee"),
        'ی' to listOf("i", "e", "y"), 'ے' to listOf("e", "ay"),
        'و' to listOf("o", "u", "v", "w", "oo"),
        'ا' to listOf("a", "aa", "i", "u", ""),
        'آ' to listOf("a", "aa"), 'ى' to listOf("a", "i"),
        'ض' to listOf("z", "d"), 'ظ' to listOf("z"), 'ذ' to listOf("z", "d"),
        'ث' to listOf("s", "th"), 'ة' to listOf("a", "t", ""),
        'ق' to listOf("q", "k"), 'ں' to listOf("n", ""),
    )
    // Single rough value for everything else (strong consonants + weak rest).
    private val rough = mapOf(
        'ب' to "b", 'پ' to "p", 'ف' to "f", 'م' to "m", 'ن' to "n", 'ل' to "l",
        'ت' to "t", 'ط' to "t", 'ٹ' to "t",
        'س' to "s", 'ص' to "s", 'ش' to "sh", 'ج' to "j", 'چ' to "ch",
        'د' to "d", 'ڈ' to "d", 'ز' to "z", 'ر' to "r", 'ڑ' to "r",
        'ك' to "k", 'ک' to "k", 'گ' to "g", 'غ' to "g", 'خ' to "kh",
        'أ' to "a", 'إ' to "a", 'ھ' to "h",
    )

    /** Plausible romanizations of an LD word, expanding multi-valued letters. */
    private fun romanVariants(word: String, cap: Int = 32): List<String> {
        var out = listOf("")
        for (c in word) {
            val opts = roughVariants[c]
            out = if (opts != null) {
                out.flatMap { v -> opts.map { v + it } }
            } else {
                val base = rough[c] ?: ""
                out.map { it + base }
            }
            if (out.size > cap) out = out.take(cap)
        }
        return out.distinct()
    }

    /** Levenshtein ratio in [0, 1] — the portable stand-in for Python's
     *  SequenceMatcher.ratio() used by the reference implementation. */
    private fun similarity(a: String, b: String): Double {
        if (a.isEmpty() && b.isEmpty()) return 1.0
        var prev = IntArray(b.length + 1) { it }
        for (i in 1..a.length) {
            val cur = IntArray(b.length + 1)
            cur[0] = i
            for (j in 1..b.length) {
                cur[j] = minOf(prev[j] + 1, cur[j - 1] + 1,
                               prev[j - 1] + if (a[i - 1] == b[j - 1]) 0 else 1)
            }
            prev = cur
        }
        return 1.0 - prev[b.length].toDouble() / maxOf(a.length, b.length)
    }

    // ── Suggestions ───────────────────────────────────────────────────────

    /** Ranked LD candidates for one Latin word. Empty when the model (or its
     *  translit table) is unavailable or nothing matches. */
    fun suggestions(model: LsdModel, latin: String, limit: Int = 3): List<String> {
        val low = latin.lowercase()
        if (low.isEmpty()) return emptyList()
        direct[low]?.let { return listOf(it) }
        // 'kh' is ambiguous — خ (fricative: خوشي) vs کھ (aspirated: دیکھو) — in
        // different skeleton buckets; search BOTH, let the dictionary decide.
        val skeletons = mutableSetOf(latinSkeleton(low))
        if ("kh" in low) skeletons.add(latinSkeleton(low.replace("kh", "k")))
        val best = mutableMapOf<String, Int>()
        for (sk in skeletons) {
            for ((word, rank) in model.translitCandidates(sk)) {
                best[word] = maxOf(best[word] ?: 0, rank)
            }
        }
        if (best.isEmpty()) return emptyList()
        val maxRank = maxOf(model.translitMaxRank, 1).toDouble()
        return best.entries
            .map { (word, rank) ->
                val sim = romanVariants(word).maxOfOrNull { similarity(low, it) } ?: 0.0
                (0.8 * sim + 0.2 * rank / maxRank) to word
            }
            // Ties sort by word DESCENDING — matches the reference's
            // sorted(..., reverse=True), which puts ماں before ما for "maa".
            .sortedWith(compareByDescending<Pair<Double, String>> { it.first }
                .thenByDescending { it.second })
            .take(limit)
            .map { it.second }
    }
}
