namespace LSDKeyboard.Tsf;

// Identical secondary map to iOS / macOS / Android / Windows hook.
// Kept as a separate file so it can be updated from one source of truth.

public static class KeyData
{
    private static readonly Dictionary<string, string> SecondaryMap = new()
    {
        ["ض"] = "ٹ",    ["ث"] = "پ",    ["ه"] = "ھ",    ["ح"] = "چ",
        ["ج"] = "چھے",   ["س"] = "ے",    ["ي"] = "ئ",    ["ا"] = "اٰ",
        ["ك"] = "گ",    ["ط"] = "ں",    ["ر"] = "ڑ",    ["ة"] = "ۃ",
        ["د"] = "ڈ",    ["ظ"] = "ہ",
    };

    public static string? SecondaryFor(string ch) =>
        SecondaryMap.TryGetValue(ch, out var s) && s.Length > 0 ? s : null;
}
