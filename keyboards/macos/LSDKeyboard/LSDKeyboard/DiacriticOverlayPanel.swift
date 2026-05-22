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
            styleMask:   [.nonactivatingPanel, .fullSizeContentView],
            backing:     .buffered,
            defer:       false
        )
        isFloatingPanel        = true
        level                  = .popUpMenu
        backgroundColor        = .clear
        isOpaque               = false
        hasShadow              = true
        hidesOnDeactivate      = false
        isReleasedWhenClosed   = false
        collectionBehavior     = [.canJoinAllSpaces, .stationary]

        let content = buildContent()
        contentView = content
        setContentSize(content.frame.size)
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
        log.info("showOverlay frame=\(NSStringFromRect(self.frame), privacy: .public) screen=\(NSStringFromRect(vis), privacy: .public)")
        orderFrontRegardless()
        log.info("showOverlay isVisible=\(self.isVisible, privacy: .public) level=\(self.level.rawValue, privacy: .public)")
    }

    func hideOverlay() {
        log.info("hideOverlay")
        orderOut(nil)
    }

    // MARK: - Layout

    private func buildContent() -> NSView {
        let vev = NSVisualEffectView()
        vev.material     = .hudWindow
        vev.blendingMode = .behindWindow
        vev.state        = .active
        vev.wantsLayer   = true
        vev.layer?.cornerRadius  = 12
        vev.layer?.masksToBounds = true

        let pad: CGFloat  = 16
        let colW: CGFloat = 380

        let tv = NSTextView()
        tv.isEditable      = false
        tv.isSelectable    = false
        tv.drawsBackground = false
        tv.textContainerInset = .zero
        tv.textContainer?.lineFragmentPadding = 0
        tv.textContainer?.containerSize =
            NSSize(width: colW, height: .greatestFiniteMagnitude)
        tv.textContainer?.widthTracksTextView = false
        // Set an initial frame so the layout manager has a valid drawing context.
        tv.frame = NSRect(x: pad, y: pad, width: colW, height: 2000)
        tv.textStorage?.setAttributedString(makeContent())
        tv.layoutManager?.ensureLayout(for: tv.textContainer!)
        let usedH = ceil(
            tv.layoutManager?.usedRect(for: tv.textContainer!).height ?? 400
        )
        log.info("buildContent usedH=\(usedH, privacy: .public) colW=\(colW, privacy: .public)")

        tv.frame  = NSRect(x: pad, y: pad, width: colW, height: usedH)
        vev.frame = NSRect(x: 0,   y: 0,
                           width:  colW + 2 * pad,
                           height: usedH + 2 * pad)
        vev.addSubview(tv)
        return vev
    }

    // MARK: - Attributed Content

    private func makeContent() -> NSAttributedString {
        let out = NSMutableAttributedString()

        // Palette (optimised for .hudWindow dark background)
        let white = NSColor.white
        let blue  = NSColor(calibratedRed: 0.45, green: 0.82, blue: 1.00, alpha: 1)
        let dim   = NSColor(white: 0.72, alpha: 1)
        let ghost = NSColor(white: 0.44, alpha: 1)

        let titleF = NSFont.systemFont(ofSize: 15, weight: .semibold)
        let secF   = NSFont.systemFont(ofSize:  9, weight: .bold)
        let keyF   = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        let charF  = NSFont.systemFont(ofSize: 13, weight: .regular)
        let descF  = NSFont.systemFont(ofSize: 10, weight: .regular)

        // Tab stops: key | char | desc --- key | char | desc
        let rowPS: NSParagraphStyle = {
            let ps = NSMutableParagraphStyle()
            ps.tabStops = [
                NSTextTab(textAlignment: .left, location:  56, options: [:]),
                NSTextTab(textAlignment: .left, location:  78, options: [:]),
                NSTextTab(textAlignment: .left, location: 200, options: [:]),
                NSTextTab(textAlignment: .left, location: 256, options: [:]),
                NSTextTab(textAlignment: .left, location: 278, options: [:]),
            ]
            return ps
        }()

        func frag(_ text: String, _ font: NSFont, _ color: NSColor) -> NSAttributedString {
            NSAttributedString(string: text,
                               attributes: [.font: font, .foregroundColor: color])
        }

        // Two-column row: key ⇥ char ⇥ desc ⇥⇥ key ⇥ char ⇥ desc
        func row2(_ k1: String, _ c1: String, _ d1: String,
                  _ k2: String, _ c2: String, _ d2: String) {
            let r = NSMutableAttributedString()
            r.append(frag(k1,        keyF,  blue));  r.append(frag("\t", keyF,  white))
            r.append(frag(c1,        charF, white)); r.append(frag("\t", charF, white))
            r.append(frag(d1,        descF, dim));   r.append(frag("\t", descF, dim))
            r.append(frag(k2,        keyF,  blue));  r.append(frag("\t", keyF,  white))
            r.append(frag(c2,        charF, white)); r.append(frag("\t", charF, white))
            r.append(frag(d2 + "\n", descF, dim))
            r.addAttribute(.paragraphStyle, value: rowPS,
                           range: NSRange(location: 0, length: r.length))
            out.append(r)
        }

        // Single-column row
        func row1(_ k: String, _ c: String, _ d: String) {
            let r = NSMutableAttributedString()
            r.append(frag(k,        keyF,  blue));  r.append(frag("\t", keyF,  white))
            r.append(frag(c,        charF, white)); r.append(frag("\t", charF, white))
            r.append(frag(d + "\n", descF, dim))
            r.addAttribute(.paragraphStyle, value: rowPS,
                           range: NSRange(location: 0, length: r.length))
            out.append(r)
        }

        func section(_ label: String) {
            out.append(frag(label + "\n", secF, ghost))
        }

        func spacer() {
            out.append(frag("\n", descF, .clear))
        }

        // ── Title ─────────────────────────────────────────────────
        out.append(frag("⌨  Diacritic Mode\n", titleF, white))
        spacer()

        // ── Diacritics ────────────────────────────────────────────
        section("DIACRITICS")
        row2("A / ;", "◌َ", "fatha",         "S / L", "◌ِ",  "kasra")
        row2("D / K", "◌ُ", "damma",         "F / J", "◌ْ",  "sukun")
        row1("G / H", "◌ّ", "shadda")
        row2("Q / P", "◌ً", "fathatan",      "W / O", "◌ٍ",  "kasratan")
        row2("E / I", "◌ٌ", "dammatan",      "R / U", "◌ٰ",  "kharo zabar")
        row2("T / Y", "◌ٓ", "maddah",        "[ / ]", "◌ٔ",  "hamza above")
        row1("B / N", "◌ٕ", "hamza below")
        spacer()

        // ── Cursor ────────────────────────────────────────────────
        section("CURSOR")
        row2("Z / /", "←", "left",     "X / .", "↑", "up")
        row2("C / ,", "↓", "down",     "V / M", "→", "right")
        spacer()

        // ── BiDi ──────────────────────────────────────────────────
        section("BIDI MARKS")
        row2("1", "LRM",  "left-to-right mark",    "2", "RLM",  "right-to-left mark")
        row2("3", "LRI",  "LTR isolate",            "4", "RLI",  "RTL isolate")
        row2("5", "PDI",  "pop directional",         "6", "ZWJ",  "zero-width joiner")
        row1("7", "ZWNJ", "zero-width non-joiner")
        spacer()

        // ── Subtending ────────────────────────────────────────────
        section("SUBTENDING MARKS")
        row2("⌥ L", "U+0601", "sanah — year sign",
             "⌥ P", "U+0603", "safha — page sign")

        return out
    }
}
