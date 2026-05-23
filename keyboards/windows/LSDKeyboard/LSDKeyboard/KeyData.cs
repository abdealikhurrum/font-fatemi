namespace LSDKeyboard;

// Double-press secondary map, settings-aware.
// Identical secondary characters to iOS / macOS / Android.

public static class KeyData
{
    /// Returns the double-press secondary for <paramref name="ch"/>, or null if none.
    /// Respects DoublePressEnabled, SelectedLayout, DoubleAlefStyle, and UrduYehStyle.
    public static string? SecondaryFor(string ch)
    {
        if (!LSDSettings.Instance.DoublePressEnabled) return null;

        return LSDSettings.Instance.SelectedLayout == "crulp_urdu"
            ? CrulpSecondaryFor(ch)
            : LsdSecondaryFor(ch);
    }

    // -------------------------------------------------------------------------
    // LSD / Arabic-Standard secondary map
    //
    // Official LSD rules (lsd.kmn):  سس→ے   ضض→ٹ   طط→ں   ظظ→ہ   حح→چ   ثث→پ   كك→گ
    // Extended quick-access:         اا→اٰ   هه→ھ   يي→ئ   رر→ڑ   دد→ڈ   ةة→ۃ   جج→چھے

    private static string? LsdSecondaryFor(string ch)
    {
        var alef = LSDSettings.Instance.DoubleAlefStyle == "alef_madda" ? "آ" : "اٰ";
        return ch switch
        {
            "ض" => "ٹ",    "ث" => "پ",    "ه" => "ھ",    "ح" => "چ",
            "ج" => "چھے",  "س" => "ے",    "ي" => "ئ",    "ا" => alef,
            "ك" => "گ",    "ط" => "ں",    "ر" => "ڑ",    "ة" => "ۃ",
            "د" => "ڈ",    "ظ" => "ہ",    _   => null,
        };
    }

    // -------------------------------------------------------------------------
    // CRULP Urdu phonetic secondary map
    //
    // عع→غ  رر→ڑ  تت→ٹ  حح→خ  دد→ڈ  ہہ→ھ  زز→ذ  شش→ض  نن→ں

    private static string? CrulpSecondaryFor(string ch) => ch switch
    {
        "ع" => "غ",    "ر" => "ڑ",    "ت" => "ٹ",    "ح" => "خ",
        "د" => "ڈ",    "ہ" => "ھ",    "ز" => "ذ",    "ش" => "ض",
        "ن" => "ں",    _   => null,
    };
}
