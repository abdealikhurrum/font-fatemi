import AppKit
import os.log

// MARK: - DiacriticOverlayPanel
//
// Floating reference card shown while Caps Lock diacritic mode is active.
// Switches content when Option is additionally held (option-mode overlay).
// Uses .nonactivatingPanel so it never steals focus from the client app.

final class DiacriticOverlayPanel: NSPanel {

    static let shared = DiacriticOverlayPanel()

    private let log = Logger(subsystem: "com.exordiumnetworks.inputmethod.lsdkeyboard",
                             category: "overlay")

    // Pre-built content views — built once, swapped cheaply on Option toggle.
    private let diacriticContent: NSView
    private let optionContent:    NSView

    private init() {
        diacriticContent = DiacriticOverlayPanel.buildDiacriticContent()
        optionContent    = DiacriticOverlayPanel.buildOptionContent()

        super.init(
            contentRect: .zero,
            styleMask:   [.nonactivatingPanel, .titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        isFloatingPanel        = true
        level                  = .popUpMenu
        isOpaque               = true
        hasShadow              = true
        hidesOnDeactivate      = false
        isReleasedWhenClosed   = false
        collectionBehavior     = [.canJoinAllSpaces, .stationary]
        title                  = "Diacritic Mode"

        // Set initial content (diacritic view).
        let sz = diacriticContent.frame.size
        contentView = diacriticContent
        setContentSize(sz)
    }

    // MARK: - Show / Hide

    func showOverlay(optionMode: Bool = false) {
        let newContent = optionMode ? optionContent : diacriticContent
        title = optionMode ? "Option Mode  (⌥)" : "Diacritic Mode  (⇪)"

        if contentView !== newContent {
            let sz = newContent.frame.size
            contentView = newContent
            setContentSize(sz)
        }

        guard let screen = NSScreen.main else {
            log.error("showOverlay: NSScreen.main is nil")
            return
        }
        let vis    = screen.visibleFrame
        let origin = NSPoint(x: vis.maxX - frame.width - 16, y: vis.minY + 16)
        setFrameOrigin(origin)
        log.info("showOverlay optionMode=\(optionMode, privacy: .public) frame=\(NSStringFromRect(self.frame), privacy: .public)")
        orderFrontRegardless()
    }

    func hideOverlay() {
        log.info("hideOverlay")
        orderOut(nil)
    }

    // MARK: - Shared layout helpers

    private static func makeTextView(width: CGFloat) -> NSTextView {
        let tv = NSTextView()
        tv.isEditable         = false
        tv.isSelectable       = false
        tv.drawsBackground    = false
        tv.textContainerInset = .zero
        tv.textContainer?.lineFragmentPadding = 0
        tv.textContainer?.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        tv.textContainer?.widthTracksTextView = false
        return tv
    }

    private static func wrap(_ tv: NSTextView, pad: CGFloat) -> NSView {
        tv.layoutManager?.ensureLayout(for: tv.textContainer!)
        let usedH = ceil(tv.layoutManager?.usedRect(for: tv.textContainer!).height ?? 400)
        tv.frame = NSRect(x: pad, y: pad, width: tv.frame.width, height: usedH)
        let box = NSView(frame: NSRect(x: 0, y: 0,
                                      width:  tv.frame.width + 2 * pad,
                                      height: usedH + 2 * pad))
        box.wantsLayer             = true
        box.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        box.addSubview(tv)
        return box
    }

    // MARK: - Diacritic content

    private static func buildDiacriticContent() -> NSView {
        let pad: CGFloat  = 14
        let colW: CGFloat = 440
        let tv = makeTextView(width: colW)
        tv.frame = NSRect(x: pad, y: pad, width: colW, height: 2000)
        tv.textStorage?.setAttributedString(makeDiacriticAttrString())
        return wrap(tv, pad: pad)
    }

    private static func makeDiacriticAttrString() -> NSAttributedString {
        let b = Builder()

        b.section("HARAKAT  (left hand)")
        b.row2("Q", "\u{064E}", "fatha",       "A", "\u{0650}", "kasra")
        b.row2("W", "\u{064B}", "fathatan",    "S", "\u{064D}", "kasratan")
        b.row2("E", "\u{064F}", "damma",       "D", "\u{0653}", "maddah")
        b.row2("R", "\u{064C}", "dammatan",    "F", "\u{0670}", "kharo zabar")
        b.row2("Z", "\u{0651}", "shadda",      "X", "\u{0652}", "sukun")
        b.row2("C", "\u{0657}", "inv. damma",  "T", "\u{0654}", "hamza above")
        b.row2("G", "\u{0655}", "hamza below", "V", "\u{0640}", "tatweel")
        b.row1("B", "\u{200D}", "ZWJ")
        b.spacer()

        b.section("SMALL QURANIC DIACRITICS  (right hand)")
        b.row2("Y", "\u{0618}", "sm. fatha",       "U", "\u{061A}", "sm. kasra")
        b.row2("I", "\u{0619}", "sm. damma",       "O", "\u{0615}", "sm. high tah")
        b.row2("P", "\u{06E4}", "sm. high madda",  "[", "\u{06E3}", "sm. low seen")
        b.row2("]", "\u{06ED}", "sm. low meem",    "H", "\u{06E7}", "sm. high yeh")
        b.row2("J", "\u{06E5}", "sm. waw",         "K", "\u{06E6}", "sm. yeh")
        b.row1("L", "\u{0616}", "sm. high lig alef-lam-yeh")
        b.spacer()

        b.section("DOCUMENT MARKS")
        b.row2("`", "\u{0614}", "takhallus",   ";",  "\u{0610}", "SAWS mark")
        b.row2("'", "\u{0611}", "AS mark",     "N",  "\u{06DD}", "end of ayah")
        b.row2("M", "\u{06DE}", "rub el hizb", ",",  "\u{06E9}", "sajda")
        b.row2(".", "\u{0601}", "sanah",        "/",  "\u{0603}", "safha")
        b.spacer()

        b.section("QURANIC MARKS  (number row)")
        b.row2("1", "\u{06D6}", "high lig \u{1E63}-l-\u{0101}",  "2", "\u{06D7}", "high lig q-l-\u{0101}")
        b.row2("3", "\u{06D8}", "high meem init",   "4", "\u{06D9}", "high lam alef")
        b.row2("5", "\u{06DA}", "high jeem",         "6", "\u{06DB}", "high 3 dots")
        b.row2("7", "\u{06DC}", "high seen",         "8", "\u{06DF}", "high round zero")
        b.row2("9", "\u{06E0}", "high rect zero",    "0", "\u{06E1}", "high dotless khah")
        b.row2("-", "\u{06E2}", "high meem isolated","=", "\u{06E8}", "high noon")

        return b.build()
    }

    // MARK: - Option content

    private static func buildOptionContent() -> NSView {
        let pad: CGFloat  = 14
        let colW: CGFloat = 440
        let tv = makeTextView(width: colW)
        tv.frame = NSRect(x: pad, y: pad, width: colW, height: 2000)
        tv.textStorage?.setAttributedString(makeOptionAttrString())
        return wrap(tv, pad: pad)
    }

    private static func makeOptionAttrString() -> NSAttributedString {
        let b = Builder()

        b.section("BIDI CONTROLS  (⌥ + number row)")
        b.row2("\u{2325}1", "\u{200E}", "LRM  left-to-right mark",    "\u{2325}2", "\u{200F}", "RLM  right-to-left mark")
        b.row2("\u{2325}3", "\u{2066}", "LRI  LTR isolate",            "\u{2325}4", "\u{2067}", "RLI  RTL isolate")
        b.row2("\u{2325}5", "\u{2069}", "PDI  pop directional",         "\u{2325}6", "\u{200D}", "ZWJ  zero-width joiner")
        b.row1("\u{2325}7", "\u{200C}", "ZWNJ  zero-width non-joiner")
        b.spacer()

        b.section("SPECIAL CHARACTERS  (⌥ + letter)")
        // QWERTY row
        b.row2("\u{2325}Q", "\u{2018}", "left single quote",   "\u{2325}W", "\u{2019}", "right single quote")
        b.row2("\u{2325}E", "\u{201C}", "left double quote",   "\u{2325}R", "\u{201D}", "right double quote")
        b.row2("\u{2325}T", "\u{0657}", "inv. damma",          "\u{2325}Y", "\u{06A4}", "ve (\u{06A4})")
        b.row2("\u{2325}O", "\u{06C1}", "he goal",             "\u{2325}[", "\u{0686}", "che")
        b.row1("\u{2325}]", "\u{06C3}", "te marbuta + ring")
        // ASDF row
        b.row2("\u{2325}A", "\u{0614}", "takhallus",           "\u{2325}S", "\u{06D2}", "ye (\u{06D2})")
        b.row2("\u{2325}D", "\u{06CC}", "farsi ye",            "\u{2325}F", "\u{067E}", "pe")
        b.row2("\u{2325}G", "\u{0653}", "maddah above",        "\u{2325}H", "\u{0670}", "kharo zabar")
        b.row2("\u{2325}J", "\u{0679}", "te with ring",        "\u{2325}K", "\u{06BA}", "nun ghunna")
        b.row2("\u{2325};", "\u{06AF}", "gaf",                 "\u{2325}U", "\u{0611}", "AS mark")
        // ZXCV row
        b.row2("\u{2325}Z", "\u{06DA}", "sm. high jeem",       "\u{2325}X", "\u{06E8}", "sm. high noon")
        b.row2("\u{2325}C", "\u{0688}", "dal with ring",       "\u{2325}V", "\u{0691}", "re with ring")
        b.row2("\u{2325}B", "\u{0698}", "zhe",                 "\u{2325}N", "\u{0613}", "sign raddah")
        b.row2("\u{2325}M", "\u{0656}", "subscript alef",      "\u{2325}/", "\u{00F7}", "division sign")
        b.row1("\u{2325}Spc", "\u{00A0}", "non-breaking space")
        b.spacer()

        b.section("SUBTENDING MARKS  (⌥ + key, then type digits)")
        b.row2("\u{2325}L", "\u{0601}", "sanah — year sign",   "\u{2325}P", "\u{0603}", "safha — page sign")

        return b.build()
    }
}

// MARK: - Builder
//
// Lightweight attributed-string builder shared by both content factories.

private final class Builder {
    private let out = NSMutableAttributedString()

    private let accent = NSColor.controlAccentColor
    private let label  = NSColor.labelColor
    private let sec    = NSColor.secondaryLabelColor
    private let ter    = NSColor.tertiaryLabelColor

    private let secF  = NSFont.systemFont(ofSize: 10, weight: .semibold)
    private let keyF  = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    private let charF = NSFont.systemFont(ofSize: 16, weight: .regular)
    private let descF = NSFont.systemFont(ofSize: 12, weight: .regular)

    private lazy var rowPS: NSParagraphStyle = {
        let ps = NSMutableParagraphStyle()
        ps.tabStops = [
            NSTextTab(textAlignment: .left, location:  56, options: [:]),
            NSTextTab(textAlignment: .left, location:  82, options: [:]),
            NSTextTab(textAlignment: .left, location: 228, options: [:]),
            NSTextTab(textAlignment: .left, location: 284, options: [:]),
            NSTextTab(textAlignment: .left, location: 310, options: [:]),
        ]
        return ps
    }()

    private func frag(_ text: String, _ font: NSFont, _ color: NSColor) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    }

    func row2(_ k1: String, _ c1: String, _ d1: String,
              _ k2: String, _ c2: String, _ d2: String) {
        let r = NSMutableAttributedString()
        r.append(frag(k1,        keyF,  accent)); r.append(frag("\t", keyF,  label))
        r.append(frag(c1,        charF, label));  r.append(frag("\t", charF, label))
        r.append(frag(d1,        descF, sec));    r.append(frag("\t", descF, sec))
        r.append(frag(k2,        keyF,  accent)); r.append(frag("\t", keyF,  label))
        r.append(frag(c2,        charF, label));  r.append(frag("\t", charF, label))
        r.append(frag(d2 + "\n", descF, sec))
        r.addAttribute(.paragraphStyle, value: rowPS, range: NSRange(location: 0, length: r.length))
        out.append(r)
    }

    func row1(_ k: String, _ c: String, _ d: String) {
        let r = NSMutableAttributedString()
        r.append(frag(k,        keyF,  accent)); r.append(frag("\t", keyF,  label))
        r.append(frag(c,        charF, label));  r.append(frag("\t", charF, label))
        r.append(frag(d + "\n", descF, sec))
        r.addAttribute(.paragraphStyle, value: rowPS, range: NSRange(location: 0, length: r.length))
        out.append(r)
    }

    func section(_ title: String) {
        out.append(frag(title + "\n", secF, ter))
    }

    func spacer() {
        out.append(frag("\n", descF, .clear))
    }

    func build() -> NSAttributedString { out }
}
