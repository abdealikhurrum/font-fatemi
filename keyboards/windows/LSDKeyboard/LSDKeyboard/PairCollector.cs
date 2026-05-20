using Microsoft.Data.Sqlite;

namespace LSDKeyboard;

// Schema is identical to iOS / macOS / Android so all platform databases
// can be merged into one corpus without any transformation.
//
// Database location: %APPDATA%\LSDKeyboard\lsd_pairs.sqlite

public sealed class PairCollector : IDisposable
{
    public static readonly PairCollector Instance = new();

    private readonly SqliteConnection _db;

    private PairCollector()
    {
        var dir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
            "LSDKeyboard");
        Directory.CreateDirectory(dir);

        _db = new SqliteConnection($"Data Source={Path.Combine(dir, "lsd_pairs.sqlite")}");
        _db.Open();
        CreateSchema();
    }

    // -------------------------------------------------------------------------
    // Schema

    private void CreateSchema()
    {
        Exec("""
            CREATE TABLE IF NOT EXISTS pairs (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                lsd_input    TEXT    NOT NULL,
                roman_output TEXT    NOT NULL,
                source       TEXT    NOT NULL DEFAULT 'correction',
                created_at   REAL    NOT NULL,
                contributed  INTEGER NOT NULL DEFAULT 0
            );
            CREATE INDEX IF NOT EXISTS idx_contributed ON pairs (contributed);
            """);
    }

    // -------------------------------------------------------------------------
    // Recording

    public void RecordAccepted(string lsd, string roman) =>
        Insert(lsd, roman, "accepted");

    public void RecordCorrection(string lsd, string correctedRoman) =>
        Insert(lsd, correctedRoman, "correction");

    // Double-press substitution (e.g. سس → ے).
    // lsd_input    = secondary (what was inserted)
    // roman_output = primary key that triggered the rule
    public void RecordDoublePress(string primary, string secondary) =>
        Insert(secondary, primary, "double_press_windows");

    // -------------------------------------------------------------------------
    // Queries

    public int PendingCount()
    {
        using var cmd = Cmd("SELECT COUNT(*) FROM pairs WHERE contributed = 0");
        return Convert.ToInt32(cmd.ExecuteScalar());
    }

    public int TotalCount()
    {
        using var cmd = Cmd("SELECT COUNT(*) FROM pairs");
        return Convert.ToInt32(cmd.ExecuteScalar());
    }

    public IReadOnlyList<(long Id, string Lsd, string Roman)> FetchPending(int limit = 2000)
    {
        using var cmd = Cmd(
            "SELECT id, lsd_input, roman_output FROM pairs WHERE contributed = 0 LIMIT @lim");
        cmd.Parameters.AddWithValue("@lim", limit);

        var results = new List<(long, string, string)>();
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            results.Add((reader.GetInt64(0), reader.GetString(1), reader.GetString(2)));
        return results;
    }

    public void MarkContributed(IEnumerable<long> ids)
    {
        var list = ids.ToList();
        if (list.Count == 0) return;
        var placeholders = string.Join(",", list.Select((_, i) => $"@p{i}"));
        using var cmd = Cmd($"UPDATE pairs SET contributed = 1 WHERE id IN ({placeholders})");
        for (int i = 0; i < list.Count; i++)
            cmd.Parameters.AddWithValue($"@p{i}", list[i]);
        cmd.ExecuteNonQuery();
    }

    public void DeleteAll() => Exec("DELETE FROM pairs");

    // -------------------------------------------------------------------------
    // Helpers

    private void Insert(string lsd, string roman, string source)
    {
        using var cmd = Cmd(
            "INSERT INTO pairs (lsd_input, roman_output, source, created_at) VALUES (@l,@r,@s,@t)");
        cmd.Parameters.AddWithValue("@l", lsd);
        cmd.Parameters.AddWithValue("@r", roman);
        cmd.Parameters.AddWithValue("@s", source);
        cmd.Parameters.AddWithValue("@t", DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() / 1000.0);
        cmd.ExecuteNonQuery();
    }

    private SqliteCommand Cmd(string sql)
    {
        var cmd = _db.CreateCommand();
        cmd.CommandText = sql;
        return cmd;
    }

    private void Exec(string sql) { using var cmd = Cmd(sql); cmd.ExecuteNonQuery(); }

    public void Dispose() => _db.Dispose();
}
