using System.Text.Json;
using System.Text.Json.Serialization;

namespace LSDKeyboard;

// Persists to %APPDATA%\LSDKeyboard\settings.json — same directory as the
// SQLite corpus database. Keys match the iOS/macOS UserDefaults keys so
// settings files are human-readable and consistent across platforms.

public sealed class LSDSettings
{
    public static readonly LSDSettings Instance = new();

    private static readonly string FilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "LSDKeyboard", "settings.json");

    private static readonly JsonSerializerOptions JsonOpts =
        new() { WriteIndented = true, DefaultIgnoreCondition = JsonIgnoreCondition.Never };

    private SettingsData _data;

    private LSDSettings() { _data = Load(); }

    // -------------------------------------------------------------------------
    // Properties

    public bool DoublePressEnabled
    {
        get => _data.DoublePressEnabled;
        set { _data.DoublePressEnabled = value; Save(); }
    }

    public string DoublePressDelayPreset
    {
        get => _data.DoublePressDelayPreset;
        set { _data.DoublePressDelayPreset = value; Save(); }
    }

    public TimeSpan DoublePressDelay => _data.DoublePressDelayPreset switch
    {
        "short" => TimeSpan.FromMilliseconds(250),
        "long"  => TimeSpan.FromMilliseconds(500),
        _       => TimeSpan.FromMilliseconds(350),
    };

    public string DoubleAlefStyle
    {
        get => _data.DoubleAlefStyle;
        set { _data.DoubleAlefStyle = value; Save(); }
    }

    public string UrduYehStyle
    {
        get => _data.UrduYehStyle;
        set { _data.UrduYehStyle = value; Save(); }
    }

    public string SelectedLayout
    {
        get => _data.SelectedLayout;
        set { _data.SelectedLayout = value; Save(); }
    }

    // -------------------------------------------------------------------------
    // Persistence

    private static SettingsData Load()
    {
        try
        {
            if (File.Exists(FilePath))
                return JsonSerializer.Deserialize<SettingsData>(
                    File.ReadAllText(FilePath)) ?? new();
        }
        catch { }
        return new();
    }

    private void Save()
    {
        try
        {
            Directory.CreateDirectory(Path.GetDirectoryName(FilePath)!);
            File.WriteAllText(FilePath, JsonSerializer.Serialize(_data, JsonOpts));
        }
        catch { }
    }

    // -------------------------------------------------------------------------
    // Data model

    private sealed class SettingsData
    {
        [JsonPropertyName("double_tap_enabled")]
        public bool   DoublePressEnabled     { get; set; } = true;

        [JsonPropertyName("double_tap_delay_preset")]
        public string DoublePressDelayPreset { get; set; } = "normal";

        [JsonPropertyName("double_alef_style")]
        public string DoubleAlefStyle        { get; set; } = "kharo_zabar";

        [JsonPropertyName("urdu_yeh_style")]
        public string UrduYehStyle           { get; set; } = "farsi_yeh";

        [JsonPropertyName("selected_layout")]
        public string SelectedLayout         { get; set; } = "lsd";
    }
}
