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

        var session = new InsertSession(_clientId, secondary);
        context.RequestEditSession(_clientId, session, TF_ES_SYNC | TF_ES_READWRITE,
            out _);
    }

    // -------------------------------------------------------------------------
    // Edit session implementation

    [ComVisible(true)]
    [ClassInterface(ClassInterfaceType.None)]
    [Guid("B7C2D3E4-F5A6-7890-BCDE-F01234567890")]
    private sealed class InsertSession : ITfEditSession
    {
        private readonly uint   _clientId;
        private readonly string _secondary;

        internal InsertSession(uint clientId, string secondary)
        {
            _clientId  = clientId;
            _secondary = secondary;
        }

        // ec = edit cookie — valid only for the duration of this call.
        public int DoEditSession(uint ec)
        {
            // TODO: Implement full delete-previous + insert-secondary.
            //
            // Outline:
            //   1. QI the ITfContext for ITfInsertAtSelection.
            //   2. Call InsertTextAtSelection(ec, TF_IAS_QUERYONLY, ...) to get the
            //      current selection range (ITfRange*).
            //   3. ShiftStart(ec, -1, out actualShift, pHaltRange=null) to extend the
            //      range one code-unit to the left (covers the primary char).
            //   4. Call range.SetText(ec, 0, secondary, secondary.Length) to replace
            //      that range with the secondary string.
            //
            // Alternatively, use TF_IAS_NOQUERY and call InsertTextAtSelection
            // directly — TSF replaces the selection. Then separately delete the
            // char before the cursor (step 3→4 above using an empty replacement).
            //
            // Key interfaces still to declare in TsfInterfaces.cs:
            //   ITfRange  {AA80E7EB-2021-11D2-93E0-0060B067B86E}
            //     SetText(ec, dwFlags, pchText, cch) → replaces range content
            //     ShiftStart(ec, cchReq, out cchActual, pHalt) → moves start left/right
            //   ITfInsertAtSelection  already declared — use to get initial range

            return 0; // S_OK
        }
    }
}
