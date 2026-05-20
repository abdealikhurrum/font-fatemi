using System.Runtime.InteropServices;

namespace LSDKeyboard.Tsf;

// ============================================================================
// LSDTextInputProcessor — the TSF input method
//
// Lifetime (managed by Windows):
//   1. User selects "Lisan ud Dawat" in Language Settings.
//   2. Windows loads LSDKeyboard.Tsf.comhost.dll into every focused process.
//   3. CoCreateInstance creates this class via the CLSID below.
//   4. Activate() is called; we register our ITfKeyEventSink.
//   5. For each key event TSF calls OnTestKeyDown, then OnKeyDown if claimed.
//   6. Deactivate() is called when the user switches away.
//
// Text insertion strategy:
//   - First press of a key with a secondary: return pfEaten=false.
//     The system inserts the primary character as normal.
//   - Second press of the same key within 350 ms: return pfEaten=true.
//     We open an edit session on the ITfContext, delete the previous character
//     via ITfRange, and insert the secondary via ITfInsertAtSelection.
// ============================================================================

[ComVisible(true)]
[ClassInterface(ClassInterfaceType.None)]
[Guid(Clsid)]
public sealed class LSDTextInputProcessor : ITfTextInputProcessor, ITfKeyEventSink
{
    // These GUIDs uniquely identify this IME. Generate fresh ones for production.
    public const string Clsid            = "C4172B4F-E6D8-4C89-A6F0-28B82D531E4E";
    public const string LangProfileGuid  = "3E4B8C1A-F7D2-4E9B-A5C6-192837465011";

    // Arabic (Saudi Arabia) language identifier — 0x0401
    public const uint   LangId           = 0x0401;

    private static readonly int S_OK = 0;

    // -------------------------------------------------------------------------
    // State

    private uint           _clientId;
    private ITfKeystrokeMgr? _keystrokeMgr;
    private readonly DoublePressTracker _tracker = new();

    // -------------------------------------------------------------------------
    // ITfTextInputProcessor

    public int Activate(ITfThreadMgr ptim, uint tid)
    {
        _clientId     = tid;
        _keystrokeMgr = (ITfKeystrokeMgr)ptim;  // QI — same object implements both
        return _keystrokeMgr.AdviseKeyEventSink(tid, this, fForeground: true);
    }

    public int Deactivate()
    {
        _keystrokeMgr?.UnadviseKeyEventSink(_clientId);
        _keystrokeMgr = null;
        _tracker.Reset();
        return S_OK;
    }

    // -------------------------------------------------------------------------
    // ITfKeyEventSink

    public int OnSetFocus(bool fForeground)
    {
        if (!fForeground) _tracker.Reset();
        return S_OK;
    }

    // TSF asks: "do you want to handle this key?"
    // Claim it if it might be a double-press trigger, so TSF doesn't route it
    // elsewhere before we see it in OnKeyDown.
    public int OnTestKeyDown(IntPtr pic, uint wParam, uint lParam, out bool pfEaten)
    {
        pfEaten = _tracker.MightHandle(wParam);
        return S_OK;
    }

    public int OnTestKeyUp(IntPtr pic, uint wParam, uint lParam, out bool pfEaten)
    {
        pfEaten = false;
        return S_OK;
    }

    public int OnKeyDown(IntPtr pic, uint wParam, uint lParam, out bool pfEaten)
    {
        pfEaten = false;

        var result = _tracker.Track(wParam, out var secondary);

        switch (result)
        {
            case DoublePressResult.FirstPress:
                // Let the key through — the system inserts the primary character.
                pfEaten = false;
                break;

            case DoublePressResult.DoublePress:
                pfEaten = true;
                // Open a synchronous edit session on the focused document context
                // to delete the primary character and insert the secondary.
                InsertSecondary(pic, secondary!);
                break;

            case DoublePressResult.NotTracked:
            default:
                pfEaten = false;
                break;
        }

        return S_OK;
    }

    public int OnKeyUp(IntPtr pic, uint wParam, uint lParam, out bool pfEaten)
    {
        pfEaten = false;
        return S_OK;
    }

    public int OnPreservedKey(IntPtr pic, in Guid rguid, out bool pfEaten)
    {
        pfEaten = false;
        return S_OK;
    }

    // -------------------------------------------------------------------------
    // Text insertion via TSF edit session
    //
    // TSF requires all document modifications to happen inside an edit session
    // requested on the ITfContext. The flow:
    //
    //   context.RequestEditSession(clientId, session, TF_ES_SYNC|TF_ES_READWRITE, ...)
    //       → session.DoEditSession(editCookie) is called synchronously
    //           → (ITfInsertAtSelection)context .InsertTextAtSelection(...)
    //              replaces the current selection with secondary text.
    //
    // To delete the previous character first, get the selection range, extend it
    // one character to the left (SetStart / ShiftStart), then replace with secondary.

    private const uint TF_ES_SYNC      = 0x00000001;
    private const uint TF_ES_READWRITE = 0x00000006;

    private void InsertSecondary(IntPtr pic, string secondary)
    {
        if (pic == IntPtr.Zero) return;

        // RCW from the raw pointer TSF gave us.
        var context = (ITfContext)Marshal.GetObjectForIUnknown(pic);

        var session = new InsertSession(_clientId, secondary, context);
        context.RequestEditSession(_clientId, session, TF_ES_SYNC | TF_ES_READWRITE,
            out _);
    }

    // -------------------------------------------------------------------------
    // Edit session implementation
    //
    // Strategy: get the current cursor selection, extend its start one character
    // to the left (covering the primary that was already inserted on the first
    // key press), then overwrite that range with the secondary string.

    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.None)]
    [Guid("B7C2D3E4-F5A6-7890-BCDE-F01234567890")]
    private sealed class InsertSession : ITfEditSession
    {
        private readonly uint       _clientId;
        private readonly string     _secondary;
        private readonly ITfContext _context;

        // TF_DEFAULT_SELECTION — retrieve the active selection (defined as (ULONG)-1).
        private const uint TF_DEFAULT_SELECTION = uint.MaxValue;

        internal InsertSession(uint clientId, string secondary, ITfContext context)
        {
            _clientId  = clientId;
            _secondary = secondary;
            _context   = context;
        }

        // ec = edit cookie — valid only for the duration of this call.
        public int DoEditSession(uint ec)
        {
            // Get the current cursor position as a zero-width ITfRange.
            int hr = _context.GetSelection(ec, TF_DEFAULT_SELECTION, 1,
                out var sel, out uint fetched);
            if (hr != 0 || fetched == 0 || sel.range == IntPtr.Zero)
                return hr == 0 ? -1 : hr; // E_FAIL if range unavailable

            var range = (ITfRange)Marshal.GetObjectForIUnknown(sel.range);

            // Extend the range start one code-unit left to cover the primary char.
            range.ShiftStart(ec, -1, out _, IntPtr.Zero);

            // Replace the primary character with the secondary string.
            range.SetText(ec, 0, _secondary, _secondary.Length);

            return 0; // S_OK
        }
    }
}
