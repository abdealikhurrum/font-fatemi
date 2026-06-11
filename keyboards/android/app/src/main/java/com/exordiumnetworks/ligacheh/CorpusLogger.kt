package com.exordiumnetworks.ligacheh

import android.content.Context
import org.json.JSONObject
import java.io.File

// Tracks every word typed with the LSD keyboard plus two behavioural signals:
//   bigrams     — which word follows which (improves next-word predictions)
//   corrections — characters backspaced within 0.6 s of insertion (mistype signal)
//
// Port of the iOS LSDLearningKB/CorpusLogger.swift, minus the touch-offset
// tracking (an iOS hit-target experiment). Storage is a JSON file in filesDir;
// the field names match the iOS CorpusData so exports stay comparable.
//
// Everything stays on-device — nothing here is ever transmitted.
class CorpusLogger private constructor(private val file: File) {

    companion object {
        private const val FILE_NAME = "lsd_corpus_words.json"

        @Volatile private var instance: CorpusLogger? = null

        fun shared(ctx: Context): CorpusLogger =
            instance ?: synchronized(this) {
                instance ?: CorpusLogger(File(ctx.applicationContext.filesDir, FILE_NAME))
                    .also { instance = it }
            }
    }

    private var pendingWord  = StringBuilder()
    private var previousWord = ""   // last fully-flushed word, for bigram recording

    // In-memory corpus — loaded lazily, written on word/correction events
    private var words:       MutableList<String>?                      = null
    private var bigrams:     MutableMap<String, MutableMap<String, Int>>? = null
    private var corrections: MutableMap<String, Int>?                  = null

    // Derived frequency table; invalidated on every save
    private var unigramFreq: Map<String, Int>? = null

    // ── Word recording ───────────────────────────────────────────────────

    /** Word-boundary characters — space, newline, Arabic/Latin punctuation. */
    private fun isBoundary(ch: Char) = ch in " \n،؛؟۔.,"

    fun record(text: String) {
        for (ch in text) {
            if (isBoundary(ch)) flush() else pendingWord.append(ch)
        }
    }

    fun recordBackspace() {
        if (pendingWord.isNotEmpty()) pendingWord.deleteCharAt(pendingWord.length - 1)
    }

    fun resetPending() {
        pendingWord = StringBuilder()
        previousWord = ""
    }

    fun flush() {
        val word = pendingWord.toString()
        pendingWord = StringBuilder()
        if (word.isEmpty()) return

        load()
        words!!.add(word)
        if (previousWord.isNotEmpty()) {
            val next = bigrams!!.getOrPut(previousWord) { mutableMapOf() }
            next[word] = (next[word] ?: 0) + 1
        }
        previousWord = word
        save()
    }

    // ── Correction tracking ──────────────────────────────────────────────

    fun recordCorrection(char: String) {
        if (char.isEmpty()) return
        load()
        corrections!![char] = (corrections!![char] ?: 0) + 1
        save()
    }

    // ── Predictions ──────────────────────────────────────────────────────

    val wordCount: Int get() { load(); return words!!.size }

    /** Top completions for `prefix`, blending bigram context with unigram frequency.
     *  Bigram matches are weighted 3× so contextual completions rise to the top. */
    fun suggestions(prefix: String, previous: String = "", limit: Int = 3): List<String> {
        if (prefix.isEmpty()) return emptyList()
        load()
        val unigrams   = buildUnigramFreq()
        val bigramNext = bigrams!![previous] ?: emptyMap<String, Int>()

        return unigrams.keys
            .filter { it.startsWith(prefix) }
            .sortedWith(Comparator { a, b ->
                val scoreA = (bigramNext[a] ?: 0) * 3 + (unigrams[a] ?: 0)
                val scoreB = (bigramNext[b] ?: 0) * 3 + (unigrams[b] ?: 0)
                if (scoreA != scoreB) scoreB - scoreA else a.length - b.length
            })
            .take(limit)
    }

    // ── Corpus management ────────────────────────────────────────────────

    fun clear() {
        words       = mutableListOf()
        bigrams     = mutableMapOf()
        corrections = mutableMapOf()
        unigramFreq = null
        pendingWord = StringBuilder()
        previousWord = ""
        writeToDisk()
    }

    fun exportText(): String { load(); return words!!.joinToString("\n") }

    // ── I/O ──────────────────────────────────────────────────────────────

    private fun load() {
        if (words != null) return
        words       = mutableListOf()
        bigrams     = mutableMapOf()
        corrections = mutableMapOf()
        runCatching {
            val root = JSONObject(file.readText())
            root.optJSONArray("words")?.let { arr ->
                for (i in 0 until arr.length()) words!!.add(arr.getString(i))
            }
            root.optJSONObject("bigrams")?.let { bg ->
                for (prev in bg.keys()) {
                    val nexts = bg.getJSONObject(prev)
                    val inner = mutableMapOf<String, Int>()
                    for (next in nexts.keys()) inner[next] = nexts.getInt(next)
                    bigrams!![prev] = inner
                }
            }
            root.optJSONObject("corrections")?.let { co ->
                for (ch in co.keys()) corrections!![ch] = co.getInt(ch)
            }
        }
    }

    private fun save() {
        unigramFreq = null
        writeToDisk()
    }

    private fun writeToDisk() {
        runCatching {
            val root = JSONObject()
            root.put("words", org.json.JSONArray(words ?: emptyList<String>()))
            val bg = JSONObject()
            for ((prev, nexts) in bigrams ?: emptyMap()) bg.put(prev, JSONObject(nexts as Map<*, *>))
            root.put("bigrams", bg)
            root.put("corrections", JSONObject((corrections ?: emptyMap<String, Int>()) as Map<*, *>))
            file.writeText(root.toString())
        }
    }

    // ── Frequency helper (lazily cached) ─────────────────────────────────

    private fun buildUnigramFreq(): Map<String, Int> {
        unigramFreq?.let { return it }
        val freq = mutableMapOf<String, Int>()
        for (w in words!!) freq[w] = (freq[w] ?: 0) + 1
        unigramFreq = freq
        return freq
    }
}
