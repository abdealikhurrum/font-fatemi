namespace LSDKeyboard;

// Double-press secondary map — identical to iOS / macOS / Android.
//
// Official LSD rules (lsd.kmn lines 57-64):
//   سس→ے   ضض→ٹ   طط→ں   ظظ→ہ   حح→چ   ثث→پ   كك→گ
// Extended quick-access secondaries:
//   اا→اٰ   هه→ھ   يي→ئ   رر→ڑ   دد→ڈ   ةة→ۃ   جج→چھے

public static class KeyData
{
    private static readonly Dictionary<string, string> SecondaryMap = new()
    {
        ["ض"] = "ٹ",    ["ث"] = "پ",    ["ه"] = "ھ",    ["ح"] = "چ",
        ["ج"] = "چھے",   ["س"] = "ے",    ["ي"] = "ئ",    ["ا"] = "اٰ",
        ["ك"] = "گ",    ["ط"] = "ں",    ["ر"] = "ڑ",    ["ة"] = "ۃ",
        ["د"] = "ڈ",    ["ظ"] = "ہ",
    };

    /// Returns the double-press secondary for <paramref name="ch"/>, or null if none.
    public static string? SecondaryFor(string ch) =>
        SecondaryMap.TryGetValue(ch, out var s) && s.Length > 0 ? s : null;
}
