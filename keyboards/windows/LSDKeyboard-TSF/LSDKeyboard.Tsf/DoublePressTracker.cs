using System.Runtime.InteropServices;
using System.Text;

namespace LSDKeyboard.Tsf;

// Encapsulates the 350 ms double-press window, shared across all platforms.
// In the TSF IME we receive virtual key codes (wParam) rather than characters,
// so we resolve VK → Unicode via ToUnicodeEx before checking the secondary map.

internal enum DoublePressResult { NotTracked, FirstPress, DoublePress }

internal sealed class DoublePressTracker
{
    private TimeSpan Window => LSDSettings.Instance.DoublePressDelay;

    private string?  _lastChar;
    private DateTime _lastTime;

    // -------------------------------------------------------------------------
    // Public API

    /// Returns true if this VK code could produce a character with a secondary.
    /// Used by OnTestKeyDown to tell TSF we might want to handle the key.
    public bool MightHandle(uint vk)
    {
        var ch = VkToChar(vk);
        return ch is not null && KeyData.SecondaryFor(ch) is not null;
    }

    /// Tracks the key press and returns whether a double-press has occurred.
    /// On DoublePressResult.DoublePress, <paramref name="secondary"/> is set.
    public DoublePressResult Track(uint vk, out string? secondary)
    {
        secondary = null;
        var ch = VkToChar(vk);

        if (ch is null)
        {
            _lastChar = null;
            return DoublePressResult.NotTracked;
        }

        var sec = KeyData.SecondaryFor(ch);
        if (sec is null)
        {
            _lastChar = null;
            return DoublePressResult.NotTracked;
        }

        var now = DateTime.UtcNow;
        if (_lastChar == ch && (now - _lastTime) < Window)
        {
            _lastChar = null;
            secondary = sec;
            return DoublePressResult.DoublePress;
        }

        _lastChar = ch;
        _lastTime = now;
        return DoublePressResult.FirstPress;
    }

    public void Reset()
    {
        _lastChar = null;
        LSDSettings.Instance.Reload(); // pick up any changes from the tray settings app
    }

    // -------------------------------------------------------------------------
    // VK → Unicode via ToUnicodeEx
    //
    // Because this code runs in-process inside the focused application, the
    // keyboard layout returned by GetKeyboardLayout(GetCurrentThreadId()) is
    // the layout that produced the key event — identical to what the hook uses.

    [DllImport("user32.dll")]
    private static extern int ToUnicodeEx(
        uint wVirtKey, uint wScanCode, byte[] lpKeyState,
        StringBuilder pwszBuff, int cchBuff, uint wFlags, IntPtr dwhkl);

    [DllImport("user32.dll")]
    private static extern bool GetKeyboardState(byte[] lpKeyState);

    [DllImport("user32.dll")]
    private static extern IntPtr GetKeyboardLayout(uint idThread);

    [DllImport("kernel32.dll")]
    private static extern uint GetCurrentThreadId();

    private static string? VkToChar(uint vk)
    {
        var state = new byte[256];
        if (!GetKeyboardState(state)) return null;

        var buf = new StringBuilder(8);
        var hkl = GetKeyboardLayout(GetCurrentThreadId());
        int n = ToUnicodeEx(vk, 0, state, buf, 8, 0, hkl);

        return n > 0 ? buf.ToString(0, n) : null;
    }
}
