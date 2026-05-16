import Foundation
import SQLite3

// Runs inside the keyboard extension process.
// Saves (lsd_input, roman_output) pairs to a shared SQLite database in the
// App Group container so the containing app can read them for federation.
// Pairs never leave the device through this class — only the derived weight
// delta is ever uploaded.

final class PairCollector {

    static let shared = PairCollector()

    // Must match the App Group entitlement in both targets.
    static let appGroupID = "group.com.yourorg.LisanUdDawat"

    private var db: OpaquePointer?

    private init() {
        guard let containerURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID)
        else {
            assertionFailure("App Group not configured — check entitlements")
            return
        }
        let dbURL = containerURL.appendingPathComponent("lsd_pairs.sqlite")
        sqlite3_open(dbURL.path, &db)
        createSchema()
    }

    deinit { sqlite3_close(db) }

    // MARK: - Schema

    private func createSchema() {
        execute("""
            CREATE TABLE IF NOT EXISTS pairs (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                lsd_input   TEXT    NOT NULL,
                roman_output TEXT   NOT NULL,
                source      TEXT    NOT NULL DEFAULT 'correction',
                created_at  REAL    NOT NULL,
                contributed INTEGER NOT NULL DEFAULT 0
            );
            CREATE INDEX IF NOT EXISTS idx_contributed ON pairs (contributed);
        """)
    }

    // MARK: - Recording

    // Call when the user accepts the keyboard's transliteration suggestion as-is.
    func recordAccepted(lsd: String, roman: String) {
        insert(lsd: lsd, roman: roman, source: "accepted")
    }

    // Call when the user explicitly edits a transliteration suggestion.
    // This is the highest-quality signal: the model was wrong and the user fixed it.
    func recordCorrection(lsd: String, suggestedRoman: String, correctedRoman: String) {
        // Store the corrected version; log the suggestion for diagnostics
        insert(lsd: lsd, roman: correctedRoman, source: "correction")
        _ = suggestedRoman   // retained for future error-analysis use
    }

    // MARK: - Queries

    func pendingCount() -> Int {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM pairs WHERE contributed = 0", -1, &stmt, nil)
        sqlite3_step(stmt)
        return Int(sqlite3_column_int(stmt, 0))
    }

    func totalCount() -> Int {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        sqlite3_prepare_v2(db, "SELECT COUNT(*) FROM pairs", -1, &stmt, nil)
        sqlite3_step(stmt)
        return Int(sqlite3_column_int(stmt, 0))
    }

    func fetchPending(limit: Int = 2000) -> [(lsd: String, roman: String, id: Int64)] {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        sqlite3_prepare_v2(
            db,
            "SELECT id, lsd_input, roman_output FROM pairs WHERE contributed = 0 LIMIT ?",
            -1, &stmt, nil
        )
        sqlite3_bind_int(stmt, 1, Int32(limit))

        var results: [(lsd: String, roman: String, id: Int64)] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id     = sqlite3_column_int64(stmt, 0)
            let lsd    = String(cString: sqlite3_column_text(stmt, 1))
            let roman  = String(cString: sqlite3_column_text(stmt, 2))
            results.append((lsd: lsd, roman: roman, id: id))
        }
        return results
    }

    func markContributed(ids: [Int64]) {
        guard !ids.isEmpty else { return }
        let placeholders = ids.map { _ in "?" }.joined(separator: ",")
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        sqlite3_prepare_v2(
            db,
            "UPDATE pairs SET contributed = 1 WHERE id IN (\(placeholders))",
            -1, &stmt, nil
        )
        for (i, id) in ids.enumerated() {
            sqlite3_bind_int64(stmt, Int32(i + 1), id)
        }
        sqlite3_step(stmt)
    }

    func deleteAll() {
        execute("DELETE FROM pairs")
    }

    // MARK: - Helpers

    private func insert(lsd: String, roman: String, source: String) {
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        sqlite3_prepare_v2(
            db,
            "INSERT INTO pairs (lsd_input, roman_output, source, created_at) VALUES (?,?,?,?)",
            -1, &stmt, nil
        )
        sqlite3_bind_text(stmt, 1, (lsd    as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 2, (roman  as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (source as NSString).utf8String, -1, nil)
        sqlite3_bind_double(stmt, 4, Date().timeIntervalSince1970)
        sqlite3_step(stmt)
    }

    private func execute(_ sql: String) {
        sqlite3_exec(db, sql, nil, nil, nil)
    }
}
