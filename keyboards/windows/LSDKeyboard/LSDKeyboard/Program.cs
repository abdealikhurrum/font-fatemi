using System.Windows.Forms;

namespace LSDKeyboard;

static class Program
{
    [STAThread]
    static void Main()
    {
        Application.SetHighDpiMode(HighDpiMode.SystemAware);
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        using var hook    = new KeyboardHook();
        using var tray    = BuildTray(hook);
        using var charMap = new CharacterMapForm();

        hook.Start();
        tray.Visible = true;

        // Keep the char map hidden at start; user opens it from tray.
        WireCharMap(tray, charMap, hook);

        Application.Run();
    }

    // -------------------------------------------------------------------------

    private static NotifyIcon BuildTray(KeyboardHook hook)
    {
        var menu = new ContextMenuStrip();

        var header = menu.Items.Add("Lisan ud Dawat");
        header.Enabled = false;

        menu.Items.Add(new ToolStripSeparator());

        // Diacritic mode toggle — text reflects current state
        var diacItem = (ToolStripMenuItem)menu.Items.Add("Diacritic mode: OFF  [ Scroll Lock ]");
        diacItem.Click += (_, _) => hook.ToggleDiacriticMode();

        hook.DiacriticModeChanged += on =>
            diacItem.Text = on
                ? "Diacritic mode: ON   [ Scroll Lock ]"
                : "Diacritic mode: OFF  [ Scroll Lock ]";

        menu.Items.Add(new ToolStripSeparator());

        var mapItem = menu.Items.Add("Open Character Map");

        menu.Items.Add(new ToolStripSeparator());

        // Pair stats — refreshed on menu open
        var statsItem = menu.Items.Add("Pairs: …");
        statsItem.Enabled = false;
        menu.Opening += (_, _) =>
        {
            var p = PairCollector.Instance.PendingCount();
            var t = PairCollector.Instance.TotalCount();
            statsItem.Text = $"Pairs: {t} total, {p} pending upload";
        };

        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Exit", null, (_, _) =>
        {
            PairCollector.Instance.Dispose();
            Application.Exit();
        });

        var tray = new NotifyIcon
        {
            Text             = "Lisan ud Dawat",
            Icon             = SystemIcons.Application,
            ContextMenuStrip = menu,
        };

        // Store mapItem tag so WireCharMap can attach its handler
        mapItem.Tag = "charmap";

        return tray;
    }

    private static void WireCharMap(NotifyIcon tray, CharacterMapForm charMap, KeyboardHook hook)
    {
        // Find the "Open Character Map" item by tag and attach the handler
        var menu = tray.ContextMenuStrip!;
        foreach (ToolStripItem item in menu.Items)
        {
            if (item.Tag as string == "charmap")
            {
                item.Click += (_, _) =>
                {
                    if (charMap.Visible) charMap.Hide();
                    else                 charMap.Show();
                };
                break;
            }
        }

        // Update tray tooltip when diacritic mode changes
        hook.DiacriticModeChanged += on =>
            tray.Text = on ? "Lisan ud Dawat — DIACRITIC" : "Lisan ud Dawat";
    }
}
