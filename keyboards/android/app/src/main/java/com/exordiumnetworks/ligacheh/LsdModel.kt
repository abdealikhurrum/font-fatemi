package com.exordiumnetworks.ligacheh

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import java.io.File

// Read-only engine over the bundled lsd-model.sqlite (the generic, filtered,
// neutralized model built by the lsd-corpus pipeline). Direct port of the iOS
// LSDLearningKB/LSDModel.swift — see lsd-corpus/pipeline/model.md for the spec:
//
//   words(word, rank)              completion + correction ranking
//   ngrams(prev, next, rank)       next-word with trigram→bigram backoff
//   rules(kind, frm, dst)          heh/yeh/double-press + paradigm (correct),
//                                  variant + honorific (suggest-only)
//   paradigms(lemma, stem, key, cell, form)   conjugation panels (future use)
//
// All queries are tiny indexed lookups; safe to run per keystroke.
//
// Android can't open a SQLite database directly from assets, so the file is
// copied to filesDir on first use (re-copied when the bundled size changes)
// and opened read-only. When the asset is absent (it is not committed to the
// repository), isAvailable is false and every query returns empty.
class LsdModel private constructor(private val db: SQLiteDatabase?) {

    val isAvailable: Boolean get() = db != null

    companion object {
        private const val ASSET = "lsd-model.sqlite"

        @Volatile private var instance: LsdModel? = null

        fun shared(ctx: Context): LsdModel =
            instance ?: synchronized(this) {
                instance ?: LsdModel(open(ctx.applicationContext)).also { instance = it }
            }

        private fun open(ctx: Context): SQLiteDatabase? = runCatching {
            val target = File(ctx.filesDir, ASSET)
            val assetSize = ctx.assets.open(ASSET).use { input ->
                if (!target.exists()) {
                    target.outputStream().use { input.copyTo(it) }
                    -1L // just copied; size check below is moot
                } else {
                    input.available().toLong()
                }
            }
            if (assetSize >= 0 && target.length() != assetSize) {
                ctx.assets.open(ASSET).use { input ->
                    target.outputStream().use { input.copyTo(it) }
                }
            }
            SQLiteDatabase.openDatabase(target.path, null, SQLiteDatabase.OPEN_READONLY)
        }.getOrNull()
    }

    // ── Core query helper ────────────────────────────────────────────────

    private fun query(sql: String, args: List<String>, limit: Int = 50): List<List<String>> {
        val db = db ?: return emptyList()
        return runCatching {
            db.rawQuery(sql, args.toTypedArray()).use { c ->
                val rows = mutableListOf<List<String>>()
                while (c.moveToNext() && rows.size < limit) {
                    rows.add((0 until c.columnCount).map { c.getString(it) ?: "" })
                }
                rows
            }
        }.getOrDefault(emptyList())
    }

    // ── Words ────────────────────────────────────────────────────────────

    fun contains(word: String): Boolean =
        query("SELECT 1 FROM words WHERE word = ?", listOf(word), limit = 1).isNotEmpty()

    fun rank(word: String): Int =
        query("SELECT rank FROM words WHERE word = ?", listOf(word), limit = 1)
            .firstOrNull()?.firstOrNull()?.toIntOrNull() ?: 0

    /** Batched rank lookup — one indexed query per 500 candidates instead of
     *  one per candidate (the edit-distance-1 set is ~10^3 strings). */
    private fun ranks(words: List<String>): Map<String, Int> {
        val out = mutableMapOf<String, Int>()
        var i = 0
        while (i < words.size) {
            val chunk = words.subList(i, minOf(i + 500, words.size))
            val marks = List(chunk.size) { "?" }.joinToString(",")
            for (row in query("SELECT word, rank FROM words WHERE word IN ($marks)", chunk, limit = 500)) {
                out[row[0]] = row[1].toIntOrNull() ?: 0
            }
            i += 500
        }
        return out
    }

    /** Prefix completion, most frequent first. Range scan on the PK index. */
    fun completions(prefix: String, limit: Int = 3): List<String> {
        if (prefix.isEmpty()) return emptyList()
        return query(
            "SELECT word FROM words WHERE word >= ? AND word < ? ORDER BY rank DESC, word LIMIT $limit",
            listOf(prefix, prefix + "\uFFFF")
        ).map { it[0] }
    }

    // ── Next word (trigram → bigram backoff) ─────────────────────────────

    fun nextWords(prev1: String, prev2: String? = null, limit: Int = 3): List<String> {
        val out = mutableListOf<String>()
        val contexts = mutableListOf<String>()
        if (!prev2.isNullOrEmpty()) contexts.add("$prev2 $prev1")
        contexts.add(prev1)
        for (ctx in contexts) {
            for (row in query("SELECT next FROM ngrams WHERE prev = ? ORDER BY rank DESC LIMIT $limit", listOf(ctx))) {
                if (row[0] !in out) out.add(row[0])
            }
            if (out.size >= limit) break
        }
        return out.take(limit)
    }

    // ── Clitic analysis (model.md: a cliticized valid stem is not an error) ──

    // Longest-first, as specified.
    private val proclitics = listOf("وبال", "فبال", "بال", "كال", "فال", "وال",
                                    "لل", "وب", "فب", "ول", "فل", "بل", "كل", "ال",
                                    "و", "ف", "ب", "ك", "ل")
    private val enclitics = listOf("هما", "كما", "هم", "هن", "كم", "كن", "ها",
                                   "نا", "ني", "ه", "ك", "ي")

    /** True when `word` is a shipped word, or proclitic + stem + enclitic
     *  around a shipped stem of length >= 2. */
    fun isValidForm(word: String): Boolean {
        if (contains(word)) return true
        val stems = mutableListOf(word)
        proclitics.firstOrNull { word.startsWith(it) && word.length > it.length }?.let {
            stems.add(word.substring(it.length))
        }
        for (stem in stems) {
            if (stem != word && stem.length >= 2 && contains(stem)) return true
            val e = enclitics.firstOrNull { stem.endsWith(it) && stem.length > it.length }
            if (e != null) {
                val residue = stem.dropLast(e.length)
                if (residue.length >= 2 && contains(residue)) return true
            }
        }
        return false
    }

    // ── Corrections (rules + edit-distance-1, ranked by word rank) ───────

    // Letters reachable from the LSD layouts; used for edit-1 candidate generation.
    private val alphabet = "ابتثجحخدذرزسشصضطظعغفقكلمنهويءآأؤئىةپچڈڑژگںھہيےٹ".toCharArray()

    /**
     * Correction candidates for a word that is NOT a valid form.
     * kind in (heh, yeh, double-press): substring substitution, both directions.
     * kind = paradigm: categorical errors, exact frm -> dst.
     */
    fun corrections(word: String, limit: Int = 3): List<String> {
        if (word.isEmpty() || !isAvailable || isValidForm(word)) return emptyList()
        val candidates = mutableSetOf<String>()

        // Exact paradigm corrections (بوليو -> بولو)
        for (row in query("SELECT dst FROM rules WHERE kind = 'paradigm' AND frm = ?", listOf(word))) {
            candidates.add(row[0])
        }
        // Confusion-rule substitutions, both directions, each occurrence
        for (row in query("SELECT frm, dst FROM rules WHERE kind IN ('heh','yeh','double-press')", emptyList())) {
            for ((a, b) in listOf(row[0] to row[1], row[1] to row[0])) {
                if (a.isNotEmpty() && word.contains(a)) candidates.add(word.replace(a, b))
            }
        }
        // Edit distance 1
        val chars = word.toCharArray()
        for (i in chars.indices) {                       // deletions
            candidates.add(String(chars, 0, i) + String(chars, i + 1, chars.size - i - 1))
        }
        for (i in 0 until chars.size - 1) {              // transpositions
            val t = chars.copyOf(); val tmp = t[i]; t[i] = t[i + 1]; t[i + 1] = tmp
            candidates.add(String(t))
        }
        for (i in 0..chars.size) {                       // insertions
            for (ch in alphabet) {
                candidates.add(String(chars, 0, i) + ch + String(chars, i, chars.size - i))
            }
        }
        for (i in chars.indices) {                       // substitutions
            for (ch in alphabet) {
                if (ch == chars[i]) continue
                val s = chars.copyOf(); s[i] = ch
                candidates.add(String(s))
            }
        }
        candidates.remove(word)

        return ranks(candidates.toList()).entries
            .sortedWith(compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key })
            .take(limit)
            .map { it.key }
    }

    // ── Suggest-only rules ───────────────────────────────────────────────

    /** Legitimate alternate spellings (كريسو -> كريسوں). Never auto-applied. */
    fun variants(word: String): List<String> =
        query("SELECT dst FROM rules WHERE kind = 'variant' AND frm = ?", listOf(word)).map { it[0] }

    /**
     * Honorific signs for a typed abbreviation: the last token, or the last
     * two tokens joined with a space. Suggest-only and reversible — the sign
     * replaces the abbreviation as its own token; the name is never rewritten.
     */
    fun honorifics(prev1: String, prev2: String? = null): List<Pair<String, String>> {
        val out = mutableListOf<Pair<String, String>>()
        val typedForms = mutableListOf(prev1)
        if (!prev2.isNullOrEmpty()) typedForms.add("$prev2 $prev1")
        for (typed in typedForms) {
            for (row in query("SELECT dst FROM rules WHERE kind = 'honorific' AND frm = ?", listOf(typed))) {
                out.add(typed to row[0])
            }
        }
        return out
    }

    /** Reverse lookup: the typed abbreviation(s) a sign came from. */
    fun honorificSource(sign: String): List<String> =
        query("SELECT frm FROM rules WHERE kind = 'honorific' AND dst = ?", listOf(sign)).map { it[0] }

    // ── Transliteration (translit table; see Transliterator) ─────────────

    /** Candidates sharing a Latin strong-consonant skeleton, by rank. Empty
     *  when the bundled model predates the translit table. */
    fun translitCandidates(skeleton: String, limit: Int = 500): List<Pair<String, Int>> {
        if (skeleton.isEmpty()) return emptyList()
        return query(
            "SELECT word, rank FROM translit WHERE skeleton = ? ORDER BY rank DESC LIMIT $limit",
            listOf(skeleton), limit = limit
        ).map { it[0] to (it[1].toIntOrNull() ?: 0) }
    }

    val translitMaxRank: Int by lazy {
        query("SELECT MAX(rank) FROM translit", emptyList(), limit = 1)
            .firstOrNull()?.firstOrNull()?.toIntOrNull() ?: 1
    }
}
