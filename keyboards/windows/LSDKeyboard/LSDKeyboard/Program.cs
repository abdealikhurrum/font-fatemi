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

        // Diacritic mode toggle
        var diacItem = (ToolStripMenuItem)menu.Items.Add("Diacritic mode: OFF  [ Scroll Lock ]");
        diacItem.Click += (_, _) => hook.ToggleDiacriticMode();
        hook.DiacriticModeChanged += on =>
            diacItem.Text = on
                ? "Diacritic mode: ON   [ Scroll Lock ]"
                : "Diacritic mode: OFF  [ Scroll Lock ]";

        menu.Items.Add(new ToolStripSeparator());

        // ── Layout ──────────────────────────────────────────────────────────
        var layoutMenu  = new ContextMenuStrip();
        var layoutLsd    = new ToolStripMenuItem("LSD (default)")   { RadioCheck = true, Tag = "lsd" };
        var layoutArabic = new ToolStripMenuItem("Arabic Standard") { RadioCheck = true, Tag = "arabic_standard" };
        var layoutCrulp  = new ToolStripMenuItem("CRULP Urdu")      { RadioCheck = true, Tag = "crulp_urdu" };
        foreach (var li in new[] { layoutLsd, layoutArabic, layoutCrulp })
        {
            var tag = (string)li.Tag!;
            li.Click += (_, _) => LSDSettings.Instance.SelectedLayout = tag;
        }
        var layoutSub = new ToolStripMenuItem("Layout");
        layoutSub.DropDownItems.AddRange([layoutLsd, layoutArabic, layoutCrulp]);
        menu.Items.Add(layoutSub);

        // ── Double-press ─────────────────────────────────────────────────────
        menu.Items.Add(new ToolStripSeparator());

        var dpItem = new ToolStripMenuItem("Double-press enabled");
        dpItem.Click += (_, _) =>
            LSDSettings.Instance.DoublePressEnabled = !LSDSettings.Instance.DoublePressEnabled;
        menu.Items.Add(dpItem);

        var delayShort  = new ToolStripMenuItem("Short  (250 ms)") { RadioCheck = true, Tag = "short"  };
        var delayNormal = new ToolStripMenuItem("Normal (350 ms)") { RadioCheck = true, Tag = "normal" };
        var delayLong   = new ToolStripMenuItem("Long   (500 ms)") { RadioCheck = true, Tag = "long"   };
        foreach (var di in new[] { delayShort, delayNormal, delayLong })
        {
            var tag = (string)di.Tag!;
            di.Click += (_, _) => LSDSettings.Instance.DoublePressDelayPreset = tag;
        }
        var delaySub = new ToolStripMenuItem("Double-press delay");
        delaySub.DropDownItems.AddRange([delayShort, delayNormal, delayLong]);
        menu.Items.Add(delaySub);

        // ── Double alef ──────────────────────────────────────────────────────
        menu.Items.Add(new ToolStripSeparator());

        var alefKharo = new ToolStripMenuItem("اٰ  kharo zabar (default)") { RadioCheck = true, Tag = "kharo_zabar" };
        var alefMadda = new ToolStripMenuItem("آ  alef madda")             { RadioCheck = true, Tag = "alef_madda"  };
        foreach (var ai in new[] { alefKharo, alefMadda })
        {
            var tag = (string)ai.Tag!;
            ai.Click += (_, _) => LSDSettings.Instance.DoubleAlefStyle = tag;
        }
        var alefSub = new ToolStripMenuItem("Double alef  (اا)");
        alefSub.DropDownItems.AddRange([alefKharo, alefMadda]);
        menu.Items.Add(alefSub);

        // ── Urdu yeh ─────────────────────────────────────────────────────────
        var yehFarsi  = new ToolStripMenuItem("ی  Farsi yeh (default)") { RadioCheck = true, Tag = "farsi_yeh"  };
        var yehArabic = new ToolStripMenuItem("ي  Arabic yeh")          { RadioCheck = true, Tag = "arabic_yeh" };
        foreach (var yi in new[] { yehFarsi, yehArabic })
        {
            var tag = (string)yi.Tag!;
            yi.Click += (_, _) => LSDSettings.Instance.UrduYehStyle = tag;
        }
        var yehSub = new ToolStripMenuItem("Urdu yeh  (CRULP)");
        yehSub.DropDownItems.AddRange([yehFarsi, yehArabic]);
        menu.Items.Add(yehSub);

        // ── Other ─────────────────────────────────────────────────────────────
        menu.Items.Add(new ToolStripSeparator());

        var mapItem = menu.Items.Add("Open Character Map");
        mapItem.Tag = "charmap";

        menu.Items.Add(new ToolStripSeparator());

        var statsItem = menu.Items.Add("Pairs: …");
        statsItem.Enabled = false;

        menu.Items.Add(new ToolStripSeparator());
        menu.Items.Add("Exit", null, (_, _) =>
        {
            PairCollector.Instance.Dispose();
            Application.Exit();
        });

        // Refresh checked states and stats on every open
        menu.Opening += (_, _) =>
        {
            var s = LSDSettings.Instance;

            layoutLsd.Checked     = s.SelectedLayout == "lsd";
            layoutArabic.Checked  = s.SelectedLayout == "arabic_standard";
            layoutCrulp.Checked   = s.SelectedLayout == "crulp_urdu";

            dpItem.Checked        = s.DoublePressEnabled;

            delayShort.Checked  = s.DoublePressDelayPreset == "short";
            delayNormal.Checked = s.DoublePressDelayPreset == "normal";
            delayLong.Checked   = s.DoublePressDelayPreset == "long";

            alefKharo.Checked = s.DoubleAlefStyle == "kharo_zabar";
            alefMadda.Checked = s.DoubleAlefStyle == "alef_madda";

            yehFarsi.Checked  = s.UrduYehStyle == "farsi_yeh";
            yehArabic.Checked = s.UrduYehStyle == "arabic_yeh";

            var p = PairCollector.Instance.PendingCount();
            var t = PairCollector.Instance.TotalCount();
            statsItem.Text = $"Pairs: {t} total, {p} pending upload";
        };

        return new NotifyIcon
        {
            Text             = "Lisan ud Dawat",
            Icon             = SystemIcons.Application,
            ContextMenuStrip = menu,
        };
    }

    private static void WireCharMap(NotifyIcon tray, CharacterMapForm charMap, KeyboardHook hook)
    {
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

        hook.DiacriticModeChanged += on =>
            tray.Text = on ? "Lisan ud Dawat — DIACRITIC" : "Lisan ud Dawat";
    }
}
