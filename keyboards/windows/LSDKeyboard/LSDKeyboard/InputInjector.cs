using System.Runtime.InteropServices;

namespace LSDKeyboard;

// Shared SendInput infrastructure used by both KeyboardHook and CharacterMapForm.

internal static class InputInjector
{
    // -------------------------------------------------------------------------
    // Win32 types

    private const uint   INPUT_KEYBOARD    = 1;
    private const uint   KEYEVENTF_KEYUP   = 0x0002;
    private const uint   KEYEVENTF_UNICODE = 0x0004;
    private const ushort VK_BACK           = 0x08;

    [StructLayout(LayoutKind.Sequential)]
    private struct KEYBDINPUT
    {
        public ushort wVk;
        public ushort wScan;
        public uint   dwFlags;
        public uint   time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MouseInput
    {
        public int    dx, dy;
        public uint   mouseData, dwFlags, time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct InputUnion
    {
        [FieldOffset(0)] public KEYBDINPUT ki;
        [FieldOffset(0)] public MouseInput mi;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct INPUT
    {
        public uint       type;
        public InputUnion u;
    }

    [DllImport("user32.dll")]
    private static extern uint SendInput(uint n, [In] INPUT[] inputs, int cbSize);

    private static readonly int InputSize = Marshal.SizeOf<INPUT>();

    // -------------------------------------------------------------------------
    // Public API

    /// Injects each Unicode code unit in <paramref name="text"/> as a key-down + key-up pair.
    /// All LSD characters are in the BMP so iterating over chars is correct.
    public static void InjectString(string text)
    {
        if (string.IsNullOrEmpty(text)) return;

        var inputs = new INPUT[text.Length * 2];
        for (int i = 0; i < text.Length; i++)
        {
            inputs[i * 2]     = UnicodeInput(text[i], 0);
            inputs[i * 2 + 1] = UnicodeInput(text[i], KEYEVENTF_KEYUP);
        }
        SendInput((uint)inputs.Length, inputs, InputSize);
    }

    /// Injects a backspace key-down + key-up.
    public static void InjectBackspace()
    {
        var inputs = new[]
        {
            VkInput(VK_BACK, 0, 0),
            VkInput(VK_BACK, 0, KEYEVENTF_KEYUP),
        };
        SendInput((uint)inputs.Length, inputs, InputSize);
    }

    // -------------------------------------------------------------------------
    // Helpers

    private static INPUT UnicodeInput(char c, uint extraFlags) => new()
    {
        type = INPUT_KEYBOARD,
        u    = new InputUnion
        {
            ki = new KEYBDINPUT { wVk = 0, wScan = c, dwFlags = KEYEVENTF_UNICODE | extraFlags }
        }
    };

    private static INPUT VkInput(ushort vk, ushort scan, uint flags) => new()
    {
        type = INPUT_KEYBOARD,
        u    = new InputUnion { ki = new KEYBDINPUT { wVk = vk, wScan = scan, dwFlags = flags } }
    };
}
