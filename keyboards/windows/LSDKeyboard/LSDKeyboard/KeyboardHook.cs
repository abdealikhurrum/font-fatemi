using System.Runtime.InteropServices;
using System.Text;

namespace LSDKeyboard;

// WH_KEYBOARD_LL system-wide keyboard hook.
//
// Normal mode — double-press substitution:
//   First press of a key with a secondary: let through, record (char, time).
//   Same key again within 350 ms: suppress, inject VK_BACK + secondary.
//
// Diacritic mode — toggled by Scroll Lock or tray menu:
//   Intercepts at VK level (layout-independent) and maps:
//     Q→َ  W→ِ  E→ُ  R→ْ  T→ّ  A→ً  S→ٍ  X→ٌ  `→ٰ
//   Cursor / modifier keys pass through for precise placement.
//   Any unmapped key exits diacritic mode and passes the key through.
//
// Injected events (LLKHF_INJECTED) are always passed through to prevent
// re-entrancy with our own SendInput calls.

public sealed class KeyboardHook : IDisposable
{
    // -------------------------------------------------------------------------
    // Win32 constants

    private const int  WH_KEYBOARD_LL  = 13;
    private const int  WM_KEYDOWN      = 0x0100;
    private const int  WM_SYSKEYDOWN   = 0x0104;
    private const uint LLKHF_INJECTED  = 0x10;

    // Virtual key codes
    private const uint VK_SCROLL  = 0x91;  // Scroll Lock — diacritic mode toggle
    private const uint VK_ESCAPE  = 0x1B;
    private const uint VK_LEFT    = 0x25;
    private const uint VK_UP      = 0x26;
    private const uint VK_RIGHT   = 0x27;
    private const uint VK_DOWN    = 0x28;
    private const uint VK_SHIFT   = 0x10;
    private const uint VK_CONTROL = 0x11;
    private const uint VK_MENU    = 0x12;  // Alt

    private static readonly TimeSpan DoublePressWindow = TimeSpan.FromMilliseconds(350);

    // Diacritic mode: VK code → diacritic character.
    // Keys are QWERTY positions regardless of the active Arabic keyboard layout.
    private static readonly Dictionary<uint, string> DiacriticMap = new()
    {
        [0x51] = "َ",   // Q → fatha
        [0x57] = "ِ",   // W → kasra
        [0x45] = "ُ",   // E → damma
        [0x52] = "ْ",   // R → sukun
        [0x54] = "ّ",   // T → shadda
        [0x41] = "ً",   // A → tanwin fath
        [0x53] = "ٍ",   // S → tanwin kasr
        [0x58] = "ٌ",   // X → tanwin damm
        [0xC0] = "ٰ",   // ` → superscript alef (kharo zabar)
    };

    // VK codes that pass through silently in diacritic mode without exiting it.
    private static readonly HashSet<uint> DiacriticPassthrough = new()
    {
        VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN,
        VK_SHIFT, VK_CONTROL, VK_MENU,
        0xA0, 0xA1,  // L/R Shift
        0xA2, 0xA3,  // L/R Control
        0xA4, 0xA5,  // L/R Alt
    };

    // -------------------------------------------------------------------------
    // P/Invoke structs & imports

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public uint   vkCode;
        public uint   scanCode;
        public uint   flags;
        public uint   time;
        public IntPtr dwExtraInfo;
    }

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")] private static extern IntPtr SetWindowsHookEx(
        int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);
    [DllImport("user32.dll")] private static extern bool UnhookWindowsHookEx(IntPtr hhk);
    [DllImport("user32.dll")] private static extern IntPtr CallNextHookEx(
        IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("kernel32.dll")] private static extern IntPtr GetModuleHandle(string? lpModuleName);
    [DllImport("user32.dll")] private static extern bool  GetKeyboardState(byte[] lpKeyState);
    [DllImport("user32.dll")] private static extern int   ToUnicodeEx(
        uint wVirtKey, uint wScanCode, byte[] lpKeyState,
        StringBuilder pwszBuff, int cchBuff, uint wFlags, IntPtr dwhkl);
    [DllImport("user32.dll")] private static extern IntPtr GetKeyboardLayout(uint idThread);

    // -------------------------------------------------------------------------
    // State

    private IntPtr _hook = IntPtr.Zero;
    private readonly LowLevelKeyboardProc _proc;  // pinned from GC

    // Double-press tracking (normal mode)
    private string?  _lastChar;
    private DateTime _lastTime;

    // Diacritic mode
    public bool DiacriticMode { get; private set; }
    public event Action<bool>? DiacriticModeChanged;

    // -------------------------------------------------------------------------
    // Constructor / start / stop

    public KeyboardHook() { _proc = HookCallback; }

    public void Start()
    {
        using var proc   = System.Diagnostics.Process.GetCurrentProcess();
        using var module = proc.MainModule
            ?? throw new InvalidOperationException("Cannot obtain main module handle.");
        _hook = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(module.ModuleName), 0);
    }

    public void ToggleDiacriticMode()
    {
        DiacriticMode = !DiacriticMode;
        _lastChar = null;  // clear any pending double-press state when switching modes
        DiacriticModeChanged?.Invoke(DiacriticMode);
    }

    // -------------------------------------------------------------------------
    // Hook callback

    private IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode < 0)
            return CallNextHookEx(_hook, nCode, wParam, lParam);

        var msg = (uint)wParam;
        if (msg != WM_KEYDOWN && msg != WM_SYSKEYDOWN)
            return CallNextHookEx(_hook, nCode, wParam, lParam);

        var kbs = Marshal.PtrToStructure<KBDLLHOOKSTRUCT>(lParam);

        // Always pass through events we injected ourselves.
        if ((kbs.flags & LLKHF_INJECTED) != 0)
            return CallNextHookEx(_hook, nCode, wParam, lParam);

        // Scroll Lock — toggle diacritic mode regardless of current mode.
        if (kbs.vkCode == VK_SCROLL)
        {
            ToggleDiacriticMode();
            return (IntPtr)1;
        }

        return DiacriticMode
            ? HandleDiacriticMode(kbs, lParam)
            : HandleNormalMode(kbs, lParam);
    }

    // -------------------------------------------------------------------------
    // Diacritic mode

    private IntPtr HandleDiacriticMode(KBDLLHOOKSTRUCT kbs, IntPtr lParam)
    {
        // Passthrough keys (cursor, modifiers) — don't exit diacritic mode.
        if (DiacriticPassthrough.Contains(kbs.vkCode))
            return CallNextHookEx(_hook, 0, (IntPtr)WM_KEYDOWN, lParam);

        // Escape — exit diacritic mode, suppress the key.
        if (kbs.vkCode == VK_ESCAPE)
        {
            ToggleDiacriticMode();
            return (IntPtr)1;
        }

        // Mapped diacritic key — suppress and inject the combining mark.
        if (DiacriticMap.TryGetValue(kbs.vkCode, out var diacritic))
        {
            InputInjector.InjectString(diacritic);
            return (IntPtr)1;
        }

        // Unmapped key — exit diacritic mode and let the key through.
        ToggleDiacriticMode();
        return CallNextHookEx(_hook, 0, (IntPtr)WM_KEYDOWN, lParam);
    }

    // -------------------------------------------------------------------------
    // Normal mode (double-press substitution)

    private IntPtr HandleNormalMode(KBDLLHOOKSTRUCT kbs, IntPtr lParam)
    {
        var keyState = new byte[256];
        GetKeyboardState(keyState);
        var buf = new StringBuilder(8);
        int charCount = ToUnicodeEx(kbs.vkCode, kbs.scanCode, keyState, buf, 8, 0,
            GetKeyboardLayout(0));

        if (charCount <= 0)
        {
            _lastChar = null;
            return CallNextHookEx(_hook, 0, (IntPtr)WM_KEYDOWN, lParam);
        }

        var ch        = buf.ToString(0, charCount);
        var secondary = KeyData.SecondaryFor(ch);

        if (secondary is not null)
        {
            var now = DateTime.UtcNow;
            if (_lastChar == ch && (now - _lastTime) < DoublePressWindow)
            {
                _lastChar = null;
                InputInjector.InjectBackspace();
                InputInjector.InjectString(secondary);
                PairCollector.Instance.RecordDoublePress(ch, secondary);
                return (IntPtr)1;
            }
            _lastChar = ch;
            _lastTime = now;
        }
        else
        {
            _lastChar = null;
        }

        return CallNextHookEx(_hook, 0, (IntPtr)WM_KEYDOWN, lParam);
    }

    // -------------------------------------------------------------------------
    // Dispose

    public void Dispose()
    {
        if (_hook != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_hook);
            _hook = IntPtr.Zero;
        }
    }
}
