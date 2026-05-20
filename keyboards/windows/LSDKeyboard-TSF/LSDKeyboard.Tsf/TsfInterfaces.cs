using System.Runtime.InteropServices;

namespace LSDKeyboard.Tsf;

// ============================================================================
// TSF COM interface definitions
//
// Rules for COM interface declarations in C#:
//   1. Every method must be declared in exact vtable order — skipping one
//      shifts all subsequent methods and causes silent wrong-method calls.
//   2. Methods we don't call are declared as stubs with IntPtr params to
//      satisfy the vtable while avoiding complex marshalling for unused paths.
//   3. [PreserveSig] keeps the raw HRESULT visible so we control error flow.
// ============================================================================

// ----------------------------------------------------------------------------
// ITfTextInputProcessor  {AA80E7F7-2021-11D2-93E0-0060B067B86E}
//
// The entry point for any TSF IME. Windows calls Activate() when the user
// selects our input method, Deactivate() when they switch away.

[ComImport]
[Guid("AA80E7F7-2021-11D2-93E0-0060B067B86E")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfTextInputProcessor
{
    [PreserveSig]
    int Activate(
        [In, MarshalAs(UnmanagedType.Interface)] ITfThreadMgr ptim,
        uint tid);

    [PreserveSig]
    int Deactivate();
}

// ----------------------------------------------------------------------------
// ITfKeyEventSink  {AA80E7F4-2021-11D2-93E0-0060B067B86E}
//
// We register this with ITfKeystrokeMgr::AdviseKeyEventSink. TSF calls
// OnTestKeyDown first to ask "do you want this key?" — return pfEaten=true
// to claim it. If claimed, OnKeyDown is called next to actually handle it.
//
// pic is ITfContext* for the focused document — cast it via
// Marshal.GetObjectForIUnknown(pic) when you need to insert/delete text.

[ComImport]
[Guid("AA80E7F4-2021-11D2-93E0-0060B067B86E")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfKeyEventSink
{
    [PreserveSig]
    int OnSetFocus([MarshalAs(UnmanagedType.Bool)] bool fForeground);

    [PreserveSig]
    int OnTestKeyDown(
        IntPtr pic, uint wParam, uint lParam,
        [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);

    [PreserveSig]
    int OnTestKeyUp(
        IntPtr pic, uint wParam, uint lParam,
        [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);

    [PreserveSig]
    int OnKeyDown(
        IntPtr pic, uint wParam, uint lParam,
        [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);

    [PreserveSig]
    int OnKeyUp(
        IntPtr pic, uint wParam, uint lParam,
        [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);

    [PreserveSig]
    int OnPreservedKey(
        IntPtr pic, in Guid rguid,
        [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);
}

// ----------------------------------------------------------------------------
// ITfKeystrokeMgr  {AA80E7F0-2021-11D2-93E0-0060B067B86E}
//
// Obtained via QueryInterface on ITfThreadMgr (same underlying object).
// We only call AdviseKeyEventSink / UnadviseKeyEventSink, but all 15 vtable
// slots must be declared so subsequent method offsets are correct.

[StructLayout(LayoutKind.Sequential)]
public struct TfPreservedKey { public uint uVKey, uModifiers; }

[ComImport]
[Guid("AA80E7F0-2021-11D2-93E0-0060B067B86E")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfKeystrokeMgr
{
    [PreserveSig]
    int AdviseKeyEventSink(
        uint tid,
        [In, MarshalAs(UnmanagedType.Interface)] ITfKeyEventSink pSink,
        [MarshalAs(UnmanagedType.Bool)] bool fForeground);

    [PreserveSig]
    int UnadviseKeyEventSink(uint tid);

    // Vtable stubs ─ not called but offsets must be maintained
    [PreserveSig] int GetForeground(out Guid pclsid);
    [PreserveSig] int TestKeyDown(uint wParam, uint lParam, [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);
    [PreserveSig] int TestKeyUp  (uint wParam, uint lParam, [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);
    [PreserveSig] int KeyDown    (uint wParam, uint lParam, [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);
    [PreserveSig] int KeyUp      (uint wParam, uint lParam, [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);
    [PreserveSig] int SimulateReceivingKeyEvent(uint wParam, uint lParam);
    [PreserveSig] int GetPreservedKey(IntPtr pic, in Guid rguid, out TfPreservedKey pprekey);
    [PreserveSig] int IsPreservedKey(in Guid rguid, in TfPreservedKey prekey, [MarshalAs(UnmanagedType.Bool)] out bool pfRegistered);
    [PreserveSig] int PreserveKey(uint tid, in Guid rguid, in TfPreservedKey prekey, IntPtr pchDesc, uint cchDesc);
    [PreserveSig] int UnpreserveKey(in Guid rguid, in TfPreservedKey prekey);
    [PreserveSig] int SetPreservedKeyDescription(in Guid rguid, IntPtr pchDesc, uint cchDesc);
    [PreserveSig] int GetPreservedKeyDescription(in Guid rguid, [MarshalAs(UnmanagedType.BStr)] out string pbstrDesc);
    [PreserveSig] int SimulatePreservedKey(IntPtr pic, in Guid rguid, [MarshalAs(UnmanagedType.Bool)] out bool pfEaten);
}

// ----------------------------------------------------------------------------
// ITfThreadMgr  {AA80E801-2021-11D2-93E0-0060B067B86E}
//
// Passed to Activate(). We only use it as a QI source for ITfKeystrokeMgr —
// all methods declared as stubs.

[ComImport]
[Guid("AA80E801-2021-11D2-93E0-0060B067B86E")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfThreadMgr
{
    [PreserveSig] int CreateDocumentMgr(IntPtr ppdim);
    [PreserveSig] int EnumDocumentMgrs(IntPtr ppEnum);
    [PreserveSig] int GetFocus(IntPtr ppdimFocus);
    [PreserveSig] int SetFocus(IntPtr pdimFocus);
    [PreserveSig] int AssociateFocus(IntPtr hwnd, IntPtr pdimNew, IntPtr ppdimPrev);
    [PreserveSig] int IsThreadFocus(IntPtr pdimFocus, IntPtr pfThreadFocus);
    [PreserveSig] int GetFunctionProvider(in Guid clsid, IntPtr ppFuncProv);
    [PreserveSig] int EnumFunctionProviders(IntPtr ppEnum);
    [PreserveSig] int GetGlobalCompartment(IntPtr ppCompartmentMgr);
}

// ----------------------------------------------------------------------------
// TF_SELECTION — returned by ITfContext.GetSelection.
// Contains an ITfRange* pointer and a style descriptor.

[StructLayout(LayoutKind.Sequential)]
public struct TF_SELECTIONSTYLE
{
    public uint ase;           // TfActiveSelEnd
    public int  fInterimChar;  // BOOL
}

[StructLayout(LayoutKind.Sequential)]
public struct TF_SELECTION
{
    public IntPtr            range;  // ITfRange*
    public TF_SELECTIONSTYLE style;
}

// ----------------------------------------------------------------------------
// ITfRange  {AA80E7EB-2021-11D2-93E0-0060B067B86E}
//
// Represents a span of text in a document. Methods are declared in exact
// vtable order; stubs cover slots we never call to keep subsequent offsets
// correct. We use GetText (for inspection), SetText (to overwrite the
// primary character with the secondary), and ShiftStart (to extend the
// range one character to the left to cover the primary).

[ComImport]
[Guid("AA80E7EB-2021-11D2-93E0-0060B067B86E")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfRange
{
    // vtable[3]
    [PreserveSig]
    int GetText(uint ec, uint dwFlags,
        [Out, MarshalAs(UnmanagedType.LPArray, SizeParamIndex = 3)] char[] pchText,
        uint cchMax, out uint pcch);

    // vtable[4]
    [PreserveSig]
    int SetText(uint ec, uint dwFlags,
        [MarshalAs(UnmanagedType.LPWStr)] string pchText, int cch);

    // vtable[5–7] — stubs (GetFormattedText, GetEmbedded, InsertEmbedded)
    [PreserveSig] int GetFormattedText(uint ec, IntPtr ppDataObject);
    [PreserveSig] int GetEmbedded(uint ec, in Guid rguidService, in Guid riid, out IntPtr ppunk);
    [PreserveSig] int InsertEmbedded(uint ec, uint dwFlags, IntPtr pDataObject);

    // vtable[8]
    [PreserveSig]
    int ShiftStart(uint ec, int cchReq, out int pcch, IntPtr pHalt);
}

// ----------------------------------------------------------------------------
// ITfContext  {AA80E7FD-2021-11D2-93E0-0060B067B86E}
//
// Represents the focused text document. The key method for us is
// RequestEditSession — pass an ITfEditSession to do any text modification
// inside an edit lock. Declared minimally; QI from the pic IntPtr in the
// key event callbacks.

[ComImport]
[Guid("AA80E7FD-2021-11D2-93E0-0060B067B86E")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfContext
{
    [PreserveSig] int RequestEditSession(uint tid,
        [In, MarshalAs(UnmanagedType.Interface)] ITfEditSession pEditSession,
        uint dwFlags, out int phrSession);

    // Vtable stubs — TfContext has many methods; declare the ones below
    // RequestEditSession as stubs to keep offsets valid if you need them later.
    [PreserveSig] int InWriteSession(uint tid, [MarshalAs(UnmanagedType.Bool)] out bool pfWriteSession);
    [PreserveSig] int GetSelection(uint ec, uint ulIndex, uint ulCount, out TF_SELECTION pSelection, out uint pcFetched);
    [PreserveSig] int SetSelection(uint ec, uint ulCount, IntPtr pSelection);
    [PreserveSig] int GetStart(uint ec, IntPtr ppStart);
    [PreserveSig] int GetEnd(uint ec, IntPtr ppEnd);
    [PreserveSig] int GetActiveView(IntPtr ppView);
    [PreserveSig] int EnumViews(IntPtr ppEnum);
    [PreserveSig] int GetStatus(IntPtr pdcs);
    [PreserveSig] int GetProperty(in Guid guidProp, IntPtr ppProp);
    [PreserveSig] int GetAppProperty(in Guid guidProp, IntPtr ppProp);
    [PreserveSig] int TrackProperties(IntPtr prgProp, uint cProp, IntPtr prgAppProp, uint cAppProp, IntPtr ppProperty);
    [PreserveSig] int EnumProperties(IntPtr ppEnum);
    [PreserveSig] int GetDocumentMgr(IntPtr ppDm);
    [PreserveSig] int CreateRangeBackup(uint ec, IntPtr pRange, IntPtr ppBackup);
}

// ----------------------------------------------------------------------------
// ITfEditSession  {AA80E7FF-2021-11D2-93E0-0060B067B86E}
//
// Implement this on a helper class and pass it to ITfContext::RequestEditSession.
// DoEditSession is called back inside the edit lock with a cookie for the session.
// Use ITfInsertAtSelection (QI on context) to write or delete text.

[ComImport]
[Guid("AA80E7FF-2021-11D2-93E0-0060B067B86E")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfEditSession
{
    [PreserveSig]
    int DoEditSession(uint ec);
}

// ----------------------------------------------------------------------------
// ITfInsertAtSelection  {55CE16BA-3014-41C1-9CEB-FADE1446AC6C}
//
// QI this from ITfContext inside DoEditSession to insert / replace text at
// the current selection. This is the TSF equivalent of iOS deleteBackward()
// + insertText() combined.

[ComImport]
[Guid("55CE16BA-3014-41C1-9CEB-FADE1446AC6C")]
[InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface ITfInsertAtSelection
{
    [PreserveSig]
    int InsertTextAtSelection(
        uint ec,
        uint dwFlags,                   // TF_IAS_NOQUERY=1, TF_IAS_QUERYONLY=2
        [MarshalAs(UnmanagedType.LPWStr)] string pchText,
        int  cch,
        IntPtr ppRange);                // ITfRange** — can be null if TF_IAS_NOQUERY

    [PreserveSig]
    int InsertEmbeddedAtSelection(uint ec, uint dwFlags, IntPtr pDataObject, IntPtr ppRange);
}
