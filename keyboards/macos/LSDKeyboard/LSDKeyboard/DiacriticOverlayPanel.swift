import AppKit
import os.log

// MARK: - DiacriticOverlayPanel
//
// Floating reference card shown while Caps Lock diacritic mode is active.
// Uses .nonactivatingPanel so it never steals focus from the client app.

final class DiacriticOverlayPanel: NSPanel {

    static let shared = DiacriticOverlayPanel()

    private let log = Logger(subsystem: "com.exordiumnetworks.inputmethod.lsdkeyboard",
                             category: "overlay")

    private init() {
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

        let content = buildContent()
        let panelSize = content.frame.size
        contentView   = content
        setContentSize(panelSize)
        log.info("init panelSize=\(NSStringFromSize(panelSize), privacy: .public)")
    }

    // MARK: - Show / Hide

    func showOverlay() {
        guard let screen = NSScreen.main else {
            log.error("showOverlay: NSScreen.main is nil")
            return
        }
        let vis = screen.visibleFrame
        let origin = NSPoint(x: vis.maxX - frame.width - 16, y: vis.minY + 16)
        setFrameOrigin(origin)
        log.info("showOverlay frame=\(NSStringFromRect(self.frame), privacy: .public)")
        orderFrontRegardless()
        log.info("showOverlay isVisible=\(self.isVisible, privacy: .public) level=\(self.level.rawValue, privacy: .public)")
    }

    func hideOverlay() {
        log.info("hideOverlay")
        orderOut(nil)
    }

    // MARK: - Layout

    private func buildContent() -> NSView {
        let pad: CGFloat  = 12
        let colW: CGFloat = 400

        let tv = NSTextView()
        tv.isEditable         = false
        tv.isSelectable       = false
        tv.drawsBackground    = false
        tv.textContainerInset = .zero
        tv.textContainer?.lineFragmentPadding = 0
        tv.textContainer?.containerSize =
            NSSize(width: colW, height: .greatestFiniteMagnitude)
        tv.textContainer?.widthTracksTextView = false
        tv.frame = NSRect(x: pad, y: pad, width: colW, height: 2000)
        tv.textStorage?.setAttributedString(makeContent())
        tv.layoutManager?.ensureLayout(for: tv.textContainer!)
        let usedH = ceil(
            tv.layoutManager?.usedRect(for: tv.textContainer!).height ?? 400
        )
        log.info("buildContent usedH=\(usedH, privacy: .public)")

        tv.frame = NSRect(x: pad, y: pad, width: colW, height: usedH)

        let box = NSView(frame: NSRect(x: 0, y: 0,
                                      width:  colW + 2 * pad,
                                      height: usedH + 2 * pad))
        box.wantsLayer         = true
        box.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        box.addSubview(tv)
        return box
    }

    // MARK: - Attributed Content

    private func makeContent() -> NSAttributedString {
        let out = NSMutableAttributedString()

        let accent  = NSColor.controlAccentColor
        let label   = NSColor.labelColor
        let sec     = NSColor.secondaryLabelColor
        let ter     = NSColor.tertiaryLabelColor

        let secF  = NSFont.systemFont(ofSize:  9, weight: .semibold)
        let keyF  = NSFont.monospacedSystemFont(ofSize: 10, weight: .regular)
        let charF = NSFont.systemFont(ofSize: 12, weight: .regular)
        let descF = NSFont.systemFont(ofSize: 10, weight: .regular)

        // Tab stops: key | char | desc ⇥ key | char | desc
        let rowPS: NSParagraphStyle = {
            let ps = NSMutableParagraphStyle()
            ps.tabStops = [
                NSTextTab(textAlignment: .left, location:  46, options: [:]),
                NSTextTab(textAlignment: .left, location:  66, options: [:]),
                NSTextTab(textAlignment: .left, location: 200, options: [:]),
                NSTextTab(textAlignment: .left, location: 246, options: [:]),
                NSTextTab(textAlignment: .left, location: 266, options: [:]),
            ]
            return ps
        }()

        func frag(_ text: String, _ font: NSFont, _ color: NSColor) -> NSAttributedString {
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

        func section(_ label: String) {
            out.append(frag(label + "\n", secF, ter))
        }

        func spacer() {
            out.append(frag("\n", descF, .clear))
        }

        // ── Number row — Quranic marks ────────────────────────────────────
        section("QURANIC MARKS  (number row)")
        row2("1", "\u{06D6}", "high lig ṣ-l-ā",     "2", "\u{06D7}", "high lig q-l-ā")
        row2("3", "\u{06D8}", "high meem init",       "4", "\u{06D9}", "high lam alef")
        row2("5", "\u{06DA}", "high jeem",             "6", "\u{06DB}", "high 3 dots")
        row2("7", "\u{06DC}", "high seen",             "8", "\u{06DF}", "high round zero")
        row2("9", "\u{06E0}", "high rect zero",        "0", "\u{06E1}", "high dotless khah")
        row2("-", "\u{06E2}", "high meem isolated",   "=", "\u{06E8}", "high noon")
        spacer()

        // ── QWERTY row — primary harakat ──────────────────────────────────
        section("HARAKAT  (QWERTY row)")
        row2("Q", "\u{064E}", "fatha",      "W", "\u{064B}", "fathatan")
        row2("E", "\u{064F}", "damma",      "R", "\u{064C}", "dammatan")
        row2("T", "\u{0650}", "kasra",      "Y", "\u{064D}", "kasratan")
        row2("U", "\u{0652}", "sukun",      "I", "\u{0651}", "shadda")
        row2("O", "\u{0653}", "maddah",     "P", "\u{0670}", "kharo zabar")
        row2("[", "\u{0654}", "hamza above","  ]", "\u{0655}", "hamza below")
        spacer()

        // ── ASDF row — secondary / small Quranic diacritics ───────────────
        section("SMALL QURANIC DIACRITICS  (ASDF row)")
        row2("A", "\u{0618}", "sm. fatha",   "S", "\u{061A}", "sm. kasra")
        row2("D", "\u{0619}", "sm. damma",   "F", "\u{0615}", "sm. high tah")
        row2("G", "\u{06E4}", "sm. high madda","H", "\u{06E3}", "sm. low seen")
        row2("J", "\u{06E7}", "sm. high yeh", "K", "\u{06E5}", "sm. waw")
        row2("L", "\u{06E6}", "sm. yeh",      ";", "\u{06ED}", "sm. low meem")
        row1("'", "\u{0616}", "sm. high lig alef-lam-yeh")
        spacer()

        // ── ZXCV row — document & literary marks ──────────────────────────
        section("DOCUMENT MARKS  (ZXCV row)")
        row2("`", "\u{0614}", "takhallus",   "Z", "\u{06DD}", "end of ayah")
        row2("X", "\u{06DE}", "rub el hizb", "C", "\u{06E9}", "sajda mark")
        row2("V", "\u{0601}", "sanah",        "B", "\u{0603}", "safha")
        row2("N", "\u{0610}", "SAWS mark",    "M", "\u{0611}", "AS mark")
        row2(",", "\u{0640}", "tatweel",       ".", "\u{200D}", "ZWJ")
        row1("/", "\u{200C}", "ZWNJ")

        return out
    }
}
