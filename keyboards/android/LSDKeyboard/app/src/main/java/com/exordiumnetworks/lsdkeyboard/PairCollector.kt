package com.exordiumnetworks.lsdkeyboard

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

// Schema is identical to iOS/macOS so data from all platforms can be merged.
// DB is stored in the app's private data directory (no external storage permission needed).

class PairCollector private constructor(context: Context) :
    SQLiteOpenHelper(context.applicationContext, "lsd_pairs.sqlite", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            CREATE TABLE IF NOT EXISTS pairs (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                lsd_input    TEXT    NOT NULL,
                roman_output TEXT    NOT NULL,
                source       TEXT    NOT NULL DEFAULT 'correction',
                created_at   REAL    NOT NULL,
                contributed  INTEGER NOT NULL DEFAULT 0
            )
        """.trimIndent())
        db.execSQL("CREATE INDEX IF NOT EXISTS idx_contributed ON pairs (contributed)")
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {}

    // MARK: - Recording

    fun recordAccepted(lsd: String, roman: String) = insert(lsd, roman, "accepted")

    fun recordCorrection(lsd: String, @Suppress("UNUSED_PARAMETER") suggestedRoman: String, correctedRoman: String) {
        insert(lsd, correctedRoman, "correction")
    }

    // Double-press substitution: e.g. user pressed "س" twice → "ے" was inserted.
    // lsd_input  = secondary (what was actually inserted)
    // roman_output = primary key that was pressed (records which rule fired)
    fun recordDoublePress(primary: String, secondary: String) =
        insert(secondary, primary, "double_press_android")

    // MARK: - Queries

    fun pendingCount(): Int {
        return readableDatabase.rawQuery(
            "SELECT COUNT(*) FROM pairs WHERE contributed = 0", null
        ).use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
    }

    fun totalCount(): Int {
        return readableDatabase.rawQuery("SELECT COUNT(*) FROM pairs", null)
            .use { c -> if (c.moveToFirst()) c.getInt(0) else 0 }
    }

    fun fetchPending(limit: Int = 2000): List<Triple<Long, String, String>> {
        val results = mutableListOf<Triple<Long, String, String>>()
        readableDatabase.rawQuery(
            "SELECT id, lsd_input, roman_output FROM pairs WHERE contributed = 0 LIMIT ?",
            arrayOf(limit.toString())
        ).use { c ->
            while (c.moveToNext()) {
                results += Triple(c.getLong(0), c.getString(1), c.getString(2))
            }
        }
        return results
    }

    fun markContributed(ids: List<Long>) {
        if (ids.isEmpty()) return
        val placeholders = ids.joinToString(",") { "?" }
        writableDatabase.execSQL(
            "UPDATE pairs SET contributed = 1 WHERE id IN ($placeholders)",
            ids.map { it.toString() }.toTypedArray()
        )
    }

    fun deleteAll() = writableDatabase.execSQL("DELETE FROM pairs")

    // MARK: - Helpers

    private fun insert(lsd: String, roman: String, source: String) {
        writableDatabase.execSQL(
            "INSERT INTO pairs (lsd_input, roman_output, source, created_at) VALUES (?,?,?,?)",
            arrayOf<Any>(lsd, roman, source, System.currentTimeMillis() / 1000.0)
        )
    }

    companion object {
        @Volatile private var instance: PairCollector? = null

        fun getInstance(context: Context): PairCollector =
            instance ?: synchronized(this) {
                instance ?: PairCollector(context).also { instance = it }
            }
    }
}
