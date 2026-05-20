namespace LSDKeyboard.Tsf;

// Settings-aware secondary map — identical logic to the hook project's KeyData.cs.

public static class KeyData
{
    public static string? SecondaryFor(string ch)
    {
        if (!LSDSettings.Instance.DoublePressEnabled) return null;

        return LSDSettings.Instance.SelectedLayout == "crulp_urdu"
            ? CrulpSecondaryFor(ch)
            : LsdSecondaryFor(ch);
    }

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

    private static string? CrulpSecondaryFor(string ch) => ch switch
    {
        "ع" => "غ",    "ر" => "ڑ",    "ت" => "ٹ",    "ح" => "خ",
        "د" => "ڈ",    "ہ" => "ھ",    "ز" => "ذ",    "ش" => "ض",
        "ن" => "ں",    _   => null,
    };
}
