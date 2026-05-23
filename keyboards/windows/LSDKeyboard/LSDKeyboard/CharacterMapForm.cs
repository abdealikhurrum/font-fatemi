using System.Drawing;
using System.Windows.Forms;

namespace LSDKeyboard;

// Floating character map window.
//
// ShowWithoutActivation = true keeps focus in the text editor — clicking a
// character button inserts it at the cursor without the editor losing focus.
// The window is TopMost so it stays above other windows while typing.

public sealed class CharacterMapForm : Form
{
    private static readonly Font ArabicFont   = new("Segoe UI", 14f, FontStyle.Regular);
    private static readonly Font HeaderFont   = new("Segoe UI", 8f, FontStyle.Bold);
    private static readonly Font RefFont      = new("Consolas", 8f);

    private static readonly Color BgColor     = Color.FromArgb(30, 30, 30);
    private static readonly Color BtnColor    = Color.FromArgb(55, 55, 60);
    private static readonly Color BtnHover    = Color.FromArgb(80, 80, 90);
    private static readonly Color HeaderColor = Color.FromArgb(130, 130, 140);
    private static readonly Color FgColor     = Color.White;

    // -------------------------------------------------------------------------
    // Character groups

    private static readonly (string Label, (string Char, string Hint)[] Items)[] Groups =
    [
        ("Harakat  [ Diacritic-mode keys in brackets ]", [
            ("َ",  "Q  fatha"),
            ("ِ",  "W  kasra"),
            ("ُ",  "E  damma"),
            ("ْ",  "R  sukun"),
            ("ّ",  "T  shadda"),
            ("ً",  "A  tanwin fath"),
            ("ٍ",  "S  tanwin kasr"),
            ("ٌ",  "X  tanwin damm"),
            ("ٰ",  "`  superscript alef (kharo zabar)"),
        ]),
        ("Honorifics", [
            ("ﷺ", "sallallahu alayhi wasallam"),
            ("ﷻ", "jalla jalaluhu"),
            ("ؓ",  "radi allahu anhu"),
            ("ؒ",  "rahimahullah"),
            ("ؑ",  "alayhis salam"),
            ("ؐ",  "sallallahu alayhi"),
            ("ؔ",  "takhallus"),
            ("ؕ",  "quranic sajda mark"),
            ("؈",  "fasila"),
            ("؃",  "safha end"),
        ]),
        ("Quranic & Extended Marks", [
            ("ٓ",  "maddah above"),
            ("ٔ",  "hamza above"),
            ("ٕ",  "hamza below"),
            ("؏",  "misra"),
            ("؂",  "footnote marker"),
            ("؎",  "sindhi postposition"),
            ("؁",  "end of ayah (alternate)"),
            ("؄",  "place of sajda"),
            ("؀",  "end of ayah"),
            ("۝",  "end of ayah (rounded)"),
            ("۩",  "place of sajda (filled)"),
            ("ۚ",  "small high jeem"),
            ("ۨ",  "small high noon"),
        ]),
        ("Extended Letters", [
            ("ٹ",  "tta — ضض"),
            ("پ",  "pe — ثث"),
            ("چ",  "che — حح"),
            ("ڈ",  "ddal — دد"),
            ("ڑ",  "rra — رر"),
            ("ژ",  "zhe"),
            ("ہ",  "he goal — ظظ"),
            ("ھ",  "do chashmi he — هه"),
            ("ے",  "ye — سس"),
            ("ئ",  "ye hamza — يي"),
            ("ں",  "noon ghunna — طط"),
            ("گ",  "gaf — كك"),
            ("ۃ",  "te marbuta goal — ةة"),
            ("ذ",  "thal"),
        ]),
        ("Lam-Alef Ligatures", [
            ("لا",  "lam-alef"),
            ("لأ",  "lam-alef with hamza above"),
            ("لإ",  "lam-alef with hamza below"),
            ("لآ",  "lam-alef with madda above"),
            ("لاٰ", "lam-alef with superscript alef"),
        ]),
        ("Punctuation", [
            ("۔",  "arabic full stop"),
            ("،",  "arabic comma"),
            ("؟",  "arabic question mark"),
            ("؛",  "arabic semicolon"),
            ("«",  "left double angle bracket"),
            ("»",  "right double angle bracket"),
            ("﴿",  "ornate left parenthesis"),
            ("﴾",  "ornate right parenthesis"),
            ("؍",  "date separator"),
        ]),
        ("Eastern Arabic Numerals", [
            ("١","1"), ("٢","2"), ("٣","3"), ("٤","4"), ("٥","5"),
            ("٦","6"), ("٧","7"), ("٨","8"), ("٩","9"), ("٠","0"),
            ("٪","percent"), ("٭","arabic star"),
        ]),
        ("Currency & Symbols", [
            ("₨",  "rupee sign"),
            ("؋",  "afghani sign"),
            ("؉",  "per mille sign"),
            ("؊",  "per ten thousand sign"),
        ]),
    ];

    // -------------------------------------------------------------------------
    // Construction

    public CharacterMapForm()
    {
        Text            = "LSD Character Map";
        BackColor       = BgColor;
        ForeColor       = FgColor;
        FormBorderStyle = FormBorderStyle.SizableToolWindow;
        TopMost         = true;
        StartPosition   = FormStartPosition.Manual;
        Size            = new Size(480, 560);
        AutoScroll      = true;
        Padding         = new Padding(8);

        // Position: bottom-right of the working area
        var wa   = Screen.PrimaryScreen?.WorkingArea ?? new Rectangle(0, 0, 1920, 1080);
        Location = new Point(wa.Right - Width - 16, wa.Bottom - Height - 16);

        BuildContent();
    }

    // Prevent this window from stealing focus when shown or when buttons are clicked.
    protected override bool ShowWithoutActivation => true;

    protected override CreateParams CreateParams
    {
        get
        {
            var cp = base.CreateParams;
            cp.ExStyle |= 0x08000000; // WS_EX_NOACTIVATE
            return cp;
        }
    }

    // -------------------------------------------------------------------------
    // Content builder

    private void BuildContent()
    {
        var panel = new FlowLayoutPanel
        {
            Dock          = DockStyle.Fill,
            FlowDirection = FlowDirection.TopDown,
            WrapContents  = false,
            AutoScroll    = true,
            BackColor     = BgColor,
            Padding       = new Padding(4),
        };

        foreach (var (label, items) in Groups)
        {
            // Section header
            panel.Controls.Add(new Label
            {
                Text      = label,
                Font      = HeaderFont,
                ForeColor = HeaderColor,
                AutoSize  = false,
                Size      = new Size(panel.ClientSize.Width > 0 ? panel.ClientSize.Width - 16 : 440, 18),
                Padding   = new Padding(2, 6, 0, 2),
            });

            // Row of character buttons
            var row = new FlowLayoutPanel
            {
                FlowDirection  = FlowDirection.LeftToRight,
                WrapContents   = true,
                AutoSize       = true,
                AutoSizeMode   = AutoSizeMode.GrowAndShrink,
                BackColor      = BgColor,
                Margin         = new Padding(0, 0, 0, 4),
            };

            foreach (var (ch, hint) in items)
                row.Controls.Add(MakeButton(ch, hint));

            panel.Controls.Add(row);
        }

        Controls.Add(panel);
    }

    private Button MakeButton(string ch, string hint)
    {
        var btn = new Button
        {
            Text        = ch,
            Font        = ArabicFont,
            ForeColor   = FgColor,
            BackColor   = BtnColor,
            FlatStyle   = FlatStyle.Flat,
            Size        = new Size(44, 44),
            Margin      = new Padding(2),
            RightToLeft = RightToLeft.Yes,
        };
        btn.FlatAppearance.BorderColor = Color.FromArgb(70, 70, 80);
        btn.FlatAppearance.BorderSize  = 1;

        if (!string.IsNullOrWhiteSpace(hint))
        {
            var tip = new ToolTip { ShowAlways = true };
            tip.SetToolTip(btn, hint);
        }

        btn.MouseEnter += (_, _) => btn.BackColor = BtnHover;
        btn.MouseLeave += (_, _) => btn.BackColor = BtnColor;

        btn.Click += (_, _) => InputInjector.InjectString(ch);

        return btn;
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) { ArabicFont.Dispose(); HeaderFont.Dispose(); RefFont.Dispose(); }
        base.Dispose(disposing);
    }
}
