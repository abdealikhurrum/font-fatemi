using System.Text.Json;
using System.Text.Json.Serialization;

namespace LSDKeyboard.Tsf;

// Reads from the same %APPDATA%\LSDKeyboard\settings.json written by the
// LSDKeyboard hook app, so settings are shared across both implementations.
// Settings are loaded once at first access and re-read on each Activate()
// call so changes take effect the next time the user focuses a window.

public sealed class LSDSettings
{
    public static readonly LSDSettings Instance = new();

    private static readonly string FilePath = Path.Combine(
        Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
        "LSDKeyboard", "settings.json");

    private SettingsData _data;

    private LSDSettings() { _data = Load(); }

    /// Re-reads settings from disk. Call on IME Activate() so changes made
    /// via the hook tray menu take effect without restarting the process.
    public void Reload() { _data = Load(); }

    // -------------------------------------------------------------------------
    // Properties

    public bool   DoublePressEnabled     => _data.DoublePressEnabled;
    public string DoublePressDelayPreset => _data.DoublePressDelayPreset;
    public string DoubleAlefStyle        => _data.DoubleAlefStyle;
    public string UrduYehStyle           => _data.UrduYehStyle;
    public string SelectedLayout         => _data.SelectedLayout;

    public TimeSpan DoublePressDelay => _data.DoublePressDelayPreset switch
    {
        "short" => TimeSpan.FromMilliseconds(250),
        "long"  => TimeSpan.FromMilliseconds(500),
        _       => TimeSpan.FromMilliseconds(350),
    };

    // -------------------------------------------------------------------------

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
