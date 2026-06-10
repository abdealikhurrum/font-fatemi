package com.exordiumnetworks.ligacheh

import android.content.Context
import android.util.Log
import org.json.*
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.*

// Tracks every word typed with the LSD keyboard plus three behavioural signals:
//   bigrams     — which word follows which (improves next-word predictions)
//   offsets     — per-key touch drift from key centre (hit-target tuning)
//   corrections — characters backspaced within 0.6 s of insertion (mistype signal)
//
// Storage: lsd_corpus_words.json in the app's private filesDir.
// Touch offsets accumulate in memory and are flushed to disk in persistOffsets(),
// which should be called in onFinishInput() to avoid a disk write per keypress.

object CorpusLogger {

    private const val TAG = "CorpusLogger"
    private const val FILE_NAME = "lsd_corpus_words.json"

    private var appCtx: Context? = null

    private val pendingWord = StringBuilder()
    private var previousWord = ""

    private var memCache: CorpusData? = null
    private var offsetsDirty = false

    private var unigramFreq: Map<String, Int>? = null
    private var bigramFreq:  Map<String, Map<String, Int>>? = null

    // ── Initialization ────────────────────────────────────────────────────

    fun init(context: Context) {
        if (appCtx == null) appCtx = context.applicationContext
    }

    fun preload() {
        if (memCache == null) memCache = loadFromDisk()
    }

    // ── Storage ───────────────────────────────────────────────────────────

    private fun corpusFile(): File? = appCtx?.let { File(it.filesDir, FILE_NAME) }

    // ── Word recording ────────────────────────────────────────────────────

    fun record(text: String) {
        for (ch in text) {
            when (ch) {
                ' ', '\n',
                '،', '؛', '؟', '۔',
                '.', ',' -> flush()
                else     -> pendingWord.append(ch)
            }
        }
    }

    fun recordBackspace() {
        if (pendingWord.isNotEmpty()) pendingWord.deleteCharAt(pendingWord.length - 1)
    }

    fun resetPending() {
        pendingWord.clear()
        previousWord = ""
    }

    fun flush() {
        val word = pendingWord.toString()
        pendingWord.clear()
        if (word.isEmpty()) return
        val data = loaded()
        data.words.add(word)
        if (previousWord.isNotEmpty()) {
            data.bigrams.getOrPut(previousWord) { mutableMapOf() }.merge(word, 1, Int::plus)
        }
        previousWord = word
        save(data)
        Log.d(TAG, "saved $word  (total: ${data.words.size} words)")
    }

    // ── Touch offsets (batched — call persistOffsets() on keyboard dismiss) ──

    fun recordTouchOffset(key: String, dx: Float, dy: Float) {
        val data = loaded()
        data.offsets.getOrPut(key) { OffsetStats() }.record(dx, dy)
        memCache     = data
        offsetsDirty = true
        unigramFreq  = null
        bigramFreq   = null
    }

    fun persistOffsets() {
        if (!offsetsDirty) return
        val data = memCache ?: return
        offsetsDirty = false
        maybeSnapshot(data)
        memCache = data
        writeToDisk(data)
    }

    private fun maybeSnapshot(data: CorpusData) {
        if (data.offsets.isEmpty()) return
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        if (data.snapshots.containsKey(today)) return
        data.snapshots[today] = data.offsets.mapValues { it.value.copy() }.toMutableMap()
        if (data.snapshots.size > 30) {
            val oldest = data.snapshots.keys.sorted().take(data.snapshots.size - 30)
            oldest.forEach { data.snapshots.remove(it) }
        }
    }

    // ── Character-transition recording (feeds probabilistic hit scoring) ──

    fun recordCharTransition(prev: Char, next: String) {
        if (prev.isWhitespace() || next.isEmpty()) return
        val data = loaded()
        data.charBigrams.getOrPut(prev.toString()) { mutableMapOf() }.merge(next, 1, Int::plus)
        memCache     = data
        offsetsDirty = true
    }

    // ── Probabilistic scoring ─────────────────────────────────────────────

    // Gaussian likelihood that a touch at (dx, dy) from a key's visual centre
    // belongs to that key. Returns 1.0 (neutral) with fewer than 5 samples.
    fun touchScore(key: String, dx: Float, dy: Float): Float {
        val minStd    = 8f
        val dfltMeanY = -2f   // global downward tap bias before per-key data exists
        val s = memCache?.offsets?.get(key)
        if (s != null && s.count >= 5) {
            val stdX  = maxOf(s.stdDx, minStd)
            val stdY  = maxOf(s.stdDy, minStd)
            val adjDx = dx - s.meanDx
            val adjDy = dy - s.meanDy
            return exp(-(adjDx * adjDx / (2 * stdX * stdX)
                       + adjDy * adjDy / (2 * stdY * stdY)).toDouble()).toFloat()
        }
        val std   = 12f
        val adjDy = dy - dfltMeanY
        return exp(-(dx * dx + adjDy * adjDy) / (2 * std * std).toDouble()).toFloat()
    }

    // Laplace-smoothed probability that `char` follows `after` in the character stream.
    // Returns 1.0 (flat prior) at word boundaries or when no data exists yet.
    fun characterPrior(char: String, after: String): Float {
        val first = after.firstOrNull() ?: return 1f
        if (first.isWhitespace()) return 1f
        val nexts = memCache?.charBigrams?.get(after) ?: return 1f
        if (nexts.isEmpty()) return 1f
        val total = nexts.values.sum().toFloat()
        val count = (nexts[char] ?: 0).toFloat()
        return (count + 0.1f) / (total + 0.1f * (nexts.size + 1))
    }

    // ── Correction tracking ───────────────────────────────────────────────

    fun recordCorrection(char: String) {
        if (char.isEmpty()) return
        val data = loaded()
        data.corrections.merge(char, 1, Int::plus)
        save(data)
    }

    // ── Predictions ───────────────────────────────────────────────────────

    val wordCount: Int get() = memCache?.words?.size ?: 0

    // Top completions for `prefix`, blending bigram context with unigram frequency.
    // Bigram matches are weighted 3× so contextual completions rise to the top.
    fun suggestions(prefix: String, after: String = "", limit: Int = 3): List<String> {
        if (prefix.isEmpty()) return emptyList()
        val data      = loaded()
        val unigrams  = buildUnigramFreq(data)
        val bigramNext = buildBigramFreq(data)[after] ?: emptyMap()

        return unigrams.keys
            .filter { it.startsWith(prefix) }
            .sortedWith(Comparator { a, b ->
                val sa = (bigramNext[a] ?: 0) * 3 + (unigrams[a] ?: 0)
                val sb = (bigramNext[b] ?: 0) * 3 + (unigrams[b] ?: 0)
                if (sa != sb) sb - sa else a.length - b.length
            })
            .take(limit)
    }

    // ── Corpus management ─────────────────────────────────────────────────

    fun clear() {
        val empty = CorpusData()
        memCache     = empty
        offsetsDirty = false
        unigramFreq  = null
        bigramFreq   = null
        pendingWord.clear()
        previousWord = ""
        writeToDisk(empty)
        Log.d(TAG, "corpus cleared")
    }

    fun exportText(): String = loaded().words.joinToString("\n")

    // ── I/O ───────────────────────────────────────────────────────────────

    private fun loaded(): CorpusData {
        memCache?.let { return it }
        val data = loadFromDisk()
        memCache = data
        return data
    }

    private fun save(data: CorpusData) {
        memCache    = data
        unigramFreq = null
        bigramFreq  = null
        writeToDisk(data)
    }

    private fun loadFromDisk(): CorpusData {
        val file = corpusFile() ?: return CorpusData()
        if (!file.exists()) return CorpusData()
        return try {
            CorpusData.fromJson(JSONObject(file.readText()))
        } catch (e: Exception) {
            // Migrate legacy flat [String] format
            try {
                val arr = JSONArray(file.readText())
                val words = (0 until arr.length()).map { arr.getString(it) }
                Log.d(TAG, "migrating legacy word list (${words.size} words)")
                val migrated = CorpusData().also { it.words.addAll(words) }
                writeToDisk(migrated)
                migrated
            } catch (e2: Exception) {
                CorpusData()
            }
        }
    }

    private fun writeToDisk(data: CorpusData) {
        val file = corpusFile() ?: return
        try {
            file.writeText(data.toJson().toString())
        } catch (e: Exception) {
            Log.w(TAG, "write failed: ${e.message}")
        }
    }

    // ── Frequency helpers (lazily cached) ─────────────────────────────────

    private fun buildUnigramFreq(data: CorpusData): Map<String, Int> {
        unigramFreq?.let { return it }
        val freq = mutableMapOf<String, Int>()
        for (w in data.words) freq.merge(w, 1, Int::plus)
        return freq.also { unigramFreq = it }
    }

    private fun buildBigramFreq(data: CorpusData): Map<String, Map<String, Int>> {
        bigramFreq?.let { return it }
        return data.bigrams.also { bigramFreq = it }
    }
}

// ── Data model ────────────────────────────────────────────────────────────────

data class OffsetStats(
    var count:  Int   = 0,
    var meanDx: Float = 0f,
    var meanDy: Float = 0f,
    var m2Dx:   Float = 0f,
    var m2Dy:   Float = 0f
) {
    val stdDx: Float get() = if (count > 1) sqrt(m2Dx / (count - 1)) else 0f
    val stdDy: Float get() = if (count > 1) sqrt(m2Dy / (count - 1)) else 0f

    fun record(dx: Float, dy: Float) {
        count++
        val n       = count.toFloat()
        val dxDelta = dx - meanDx
        val dyDelta = dy - meanDy
        meanDx += dxDelta / n
        meanDy += dyDelta / n
        // Second-pass delta uses the updated mean — Welford numerically stable variance
        m2Dx   += dxDelta * (dx - meanDx)
        m2Dy   += dyDelta * (dy - meanDy)
    }

    fun copy() = OffsetStats(count, meanDx, meanDy, m2Dx, m2Dy)

    fun toJson(): JSONObject = JSONObject().apply {
        put("count",  count)
        put("meanDx", meanDx.toDouble())
        put("meanDy", meanDy.toDouble())
        put("m2Dx",   m2Dx.toDouble())
        put("m2Dy",   m2Dy.toDouble())
    }

    companion object {
        fun fromJson(j: JSONObject) = OffsetStats(
            count  = j.optInt("count"),
            meanDx = j.optDouble("meanDx", 0.0).toFloat(),
            meanDy = j.optDouble("meanDy", 0.0).toFloat(),
            m2Dx   = j.optDouble("m2Dx",   0.0).toFloat(),
            m2Dy   = j.optDouble("m2Dy",   0.0).toFloat()
        )
    }
}

class CorpusData {
    val words:       MutableList<String>                                  = mutableListOf()
    val bigrams:     MutableMap<String, MutableMap<String, Int>>          = mutableMapOf()
    val charBigrams: MutableMap<String, MutableMap<String, Int>>          = mutableMapOf()
    val offsets:     MutableMap<String, OffsetStats>                      = mutableMapOf()
    val corrections: MutableMap<String, Int>                              = mutableMapOf()
    val snapshots:   MutableMap<String, MutableMap<String, OffsetStats>>  = mutableMapOf()

    fun toJson(): JSONObject = JSONObject().apply {
        put("words",       JSONArray().also { a -> words.forEach { a.put(it) } })
        put("bigrams",     nestedIntMapToJson(bigrams))
        put("charBigrams", nestedIntMapToJson(charBigrams))
        put("offsets",     JSONObject().also { o -> offsets.forEach    { (k, v) -> o.put(k, v.toJson()) } })
        put("corrections", JSONObject().also { o -> corrections.forEach { (k, v) -> o.put(k, v) } })
        put("snapshots",   JSONObject().also { outer ->
            snapshots.forEach { (date, stats) ->
                outer.put(date, JSONObject().also { inner ->
                    stats.forEach { (k, v) -> inner.put(k, v.toJson()) }
                })
            }
        })
    }

    companion object {
        fun fromJson(j: JSONObject): CorpusData = CorpusData().apply {
            j.optJSONArray("words")?.let { a ->
                for (i in 0 until a.length()) words.add(a.getString(i))
            }
            bigrams.putAll(jsonToNestedIntMap(j.optJSONObject("bigrams")))
            charBigrams.putAll(jsonToNestedIntMap(j.optJSONObject("charBigrams")))
            j.optJSONObject("offsets")?.let { o ->
                o.keys().forEach { k -> offsets[k] = OffsetStats.fromJson(o.getJSONObject(k)) }
            }
            j.optJSONObject("corrections")?.let { o ->
                o.keys().forEach { k -> corrections[k] = o.getInt(k) }
            }
            j.optJSONObject("snapshots")?.let { outer ->
                outer.keys().forEach { date ->
                    val inner = outer.getJSONObject(date)
                    val m = mutableMapOf<String, OffsetStats>()
                    inner.keys().forEach { k -> m[k] = OffsetStats.fromJson(inner.getJSONObject(k)) }
                    snapshots[date] = m
                }
            }
        }

        private fun nestedIntMapToJson(m: Map<String, Map<String, Int>>): JSONObject =
            JSONObject().also { outer ->
                m.forEach { (k, v) ->
                    outer.put(k, JSONObject().also { inner -> v.forEach { (ik, iv) -> inner.put(ik, iv) } })
                }
            }

        private fun jsonToNestedIntMap(obj: JSONObject?): Map<String, MutableMap<String, Int>> {
            if (obj == null) return emptyMap()
            val result = mutableMapOf<String, MutableMap<String, Int>>()
            obj.keys().forEach { k ->
                val inner = obj.getJSONObject(k)
                val m = mutableMapOf<String, Int>()
                inner.keys().forEach { ik -> m[ik] = inner.getInt(ik) }
                result[k] = m
            }
            return result
        }
    }
}
