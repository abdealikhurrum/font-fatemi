import AppKit

// MARK: - DiacriticOverlayPanel
//
// A compact floating reference card shown while Caps Lock diacritic mode is
// active. Uses .nonactivatingPanel so it never steals focus from the text field
// being edited.

final class DiacriticOverlayPanel: NSPanel {

    static let shared = DiacriticOverlayPanel()

    private init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 268, height: 100),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .floating
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true
        hidesOnDeactivate = false
        collectionBehavior = [.canJoinAllSpaces, .stationary]

        let bg = makeBackground()
        contentView = bg
        setContentSize(bg.frame.size)
    }

    // MARK: Show / Hide

    func showOverlay() {
        guard let screen = NSScreen.main else { return }
        let vis = screen.visibleFrame
        setFrameOrigin(NSPoint(x: vis.maxX - frame.width - 12,
                               y: vis.minY + 12))
        orderFront(nil)
    }

    func hideOverlay() {
        orderOut(nil)
    }

    // MARK: Content

    private func makeBackground() -> NSView {
        let bg = NSView()
        bg.wantsLayer = true
        bg.layer?.backgroundColor = NSColor.windowBackgroundColor
            .withAlphaComponent(0.94).cgColor
        bg.layer?.cornerRadius = 10
        bg.layer?.borderWidth = 0.5
        bg.layer?.borderColor = NSColor.separatorColor
            .withAlphaComponent(0.5).cgColor

        let tv = NSTextView(frame: .zero)
        tv.isEditable = false
        tv.isSelectable = false
        tv.drawsBackground = false
        tv.backgroundColor = .clear
        tv.font = NSFont.monospacedSystemFont(ofSize: 10.5, weight: .regular)
        tv.textColor = .labelColor
        tv.textContainerInset = .zero
        tv.textContainer?.lineFragmentPadding = 0
        tv.string = referenceText

        // Size to fit content within a fixed column width.
        let colW: CGFloat = 244
        tv.textContainer?.containerSize = NSSize(width: colW,
                                                 height: .greatestFiniteMagnitude)
        tv.textContainer?.widthTracksTextView = false
        tv.layoutManager?.ensureLayout(for: tv.textContainer!)
        let used = tv.layoutManager?.usedRect(for: tv.textContainer!) ?? .zero
        let tvH = ceil(used.height)

        let pad: CGFloat = 10
        tv.frame = NSRect(x: pad, y: pad, width: colW, height: tvH)
        bg.frame  = NSRect(x: 0,   y: 0,   width: colW + 2 * pad,
                                           height: tvH + 2 * pad)
        bg.addSubview(tv)
        return bg
    }

    private let referenceText: String = """
        ⌨  Diacritic Mode  (Caps Lock)
        ─────────────────────────────────
        A / ;   ◌َ  fatha      S / L   ◌ِ  kasra
        D / K   ◌ُ  damma      F / J   ◌ْ  sukun
        G / H   ◌ّ  shadda
        Q / P   ◌ً  fathatan   W / O   ◌ٍ  kasratan
        E / I   ◌ٌ  dammatan   R / U   ◌ٰ  kharo zabar
        T / Y   ◌ٓ  maddah    [ / ]   ◌ٔ  hamza ↑
        B / N   ◌ٕ  hamza ↓
        ─────────────────────────────────
        Z / /   ←     X / .   ↑
        C / ,   ↓     V / M   →
        ─────────────────────────────────
        1  LRM    2  RLM    3  LRI    4  RLI
        5  PDI    6  ZWJ    7  ZWNJ
        ─────────────────────────────────
        ⌥ L   Sanah  (year sign)
        ⌥ P   Safha  (page sign)
        """
}
