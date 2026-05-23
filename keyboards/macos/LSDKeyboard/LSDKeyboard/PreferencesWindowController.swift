import Cocoa

// MARK: - PreferencesWindowController
//
// Process-lifetime singleton that owns the preferences window.
// Called from the IMKit menu via MenuActions.shared — avoids the cross-process
// target-action reliability issues with custom menu item targets.

final class PreferencesWindowController: NSObject, NSWindowDelegate {
    static let shared = PreferencesWindowController()
    private override init() {}

    private var window: NSWindow?

    // Weak refs so we can refresh state when the window re-opens.
    private weak var doublePressCheck: NSButton?
    private weak var delaySegment:     NSSegmentedControl?
    private weak var alefSegment:      NSSegmentedControl?
    private weak var yehSegment:       NSSegmentedControl?
    private weak var kaafSegment:      NSSegmentedControl?
    private weak var haaSegment:       NSSegmentedControl?
    private weak var taaSegment:       NSSegmentedControl?

    func showWindow() {
        if window == nil { window = makeWindow() }
        refreshControls()
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Window construction

    private func makeWindow() -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 100),
            styleMask:   [.titled, .closable],
            backing:     .buffered,
            defer:       false
        )
        w.title                 = "Lisan ud Dawat"
        w.isReleasedWhenClosed  = false
        w.delegate              = self

        let root = NSStackView()
        root.orientation   = .vertical
        root.alignment     = .leading
        root.spacing       = 10
        root.edgeInsets    = NSEdgeInsets(top: 18, left: 20, bottom: 18, right: 20)
        root.translatesAutoresizingMaskIntoConstraints = false

        // ── Double-press ────────────────────────────────────────────────────
        root.addArrangedSubview(sectionHeader("Double-press"))

        let dpCheck = NSButton(checkboxWithTitle: "Enable double-press",
                               target: self, action: #selector(toggleDoublePress(_:)))
        doublePressCheck = dpCheck
        root.addArrangedSubview(dpCheck)

        let delaySeg = segmented(["Short", "Normal", "Long"],
                                  action: #selector(setDelay(_:)))
        delaySegment = delaySeg
        root.addArrangedSubview(labeledRow("Delay", delaySeg))

        // ── Character styles ─────────────────────────────────────────────────
        root.addArrangedSubview(makeSeparator())
        root.addArrangedSubview(sectionHeader("Character Styles"))

        let alefSeg = segmented(["اٰ  kharo zabar (default)", "آ  alef madda"],
                                  action: #selector(setAlef(_:)))
        alefSegment = alefSeg
        root.addArrangedSubview(labeledRow("Double alef  اا", alefSeg))

        let yehSeg = segmented(["ي  Arabic (default)", "ی  Farsi/Urdu"],
                                action: #selector(setYeh(_:)))
        yehSegment = yehSeg
        root.addArrangedSubview(labeledRow("Yeh", yehSeg))

        let kaafSeg = segmented(["ك  Arabic (default)", "ک  Urdu"],
                                 action: #selector(setKaaf(_:)))
        kaafSegment = kaafSeg
        root.addArrangedSubview(labeledRow("Kaaf", kaafSeg))

        let haaSeg = segmented(["ه  Arabic (default)", "ہ  Urdu he goal"],
                                action: #selector(setHaa(_:)))
        haaSegment = haaSeg
        root.addArrangedSubview(labeledRow("Haa", haaSeg))

        let taaSeg = segmented(["ة  Arabic (default)", "ۃ  Urdu"],
                                action: #selector(setTaa(_:)))
        taaSegment = taaSeg
        root.addArrangedSubview(labeledRow("Taa marbuta", taaSeg))

        let content = NSView()
        content.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            root.topAnchor.constraint(equalTo: content.topAnchor),
            root.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
        w.contentView = content
        return w
    }

    // MARK: - UI helpers

    private func sectionHeader(_ text: String) -> NSTextField {
        let t = NSTextField(labelWithString: text)
        t.font      = .boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        t.textColor = .secondaryLabelColor
        return t
    }

    private func segmented(_ titles: [String], action: Selector) -> NSSegmentedControl {
        let s = NSSegmentedControl(labels: titles, trackingMode: .selectOne,
                                    target: self, action: action)
        s.segmentStyle = .roundRect
        s.font = .systemFont(ofSize: NSFont.systemFontSize)
        return s
    }

    private func labeledRow(_ text: String, _ control: NSView) -> NSStackView {
        let lbl = NSTextField(labelWithString: text)
        lbl.font = .systemFont(ofSize: NSFont.systemFontSize)
        lbl.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        lbl.widthAnchor.constraint(equalToConstant: 110).isActive = true

        let row = NSStackView(views: [lbl, control])
        row.orientation = .horizontal
        row.spacing     = 10
        row.alignment   = .centerY
        return row
    }

    private func makeSeparator() -> NSBox {
        let b = NSBox()
        b.boxType = .separator
        return b
    }

    // MARK: - State refresh

    func refreshControls() {
        doublePressCheck?.state = KeyboardSettings.doublePressEnabled ? .on : .off
        delaySegment?.selectedSegment = {
            switch KeyboardSettings.doublePressDelayPreset {
            case .short:  return 0
            case .normal: return 1
            case .long:   return 2
            }
        }()
        alefSegment?.selectedSegment = KeyboardSettings.doubleAlefStyle  == .kharoZabar      ? 0 : 1
        yehSegment?.selectedSegment  = KeyboardSettings.urduYehStyle     == .arabicYeh        ? 0 : 1
        kaafSegment?.selectedSegment = KeyboardSettings.urduKaafStyle    == .arabicKaaf       ? 0 : 1
        haaSegment?.selectedSegment  = KeyboardSettings.urduHaaStyle     == .arabicHaa        ? 0 : 1
        taaSegment?.selectedSegment  = KeyboardSettings.urduTaaMarbutaStyle == .arabicTaaMarbuta ? 0 : 1
    }

    // MARK: - Actions

    @objc private func toggleDoublePress(_ sender: NSButton) {
        KeyboardSettings.doublePressEnabled = (sender.state == .on)
    }

    @objc private func setDelay(_ sender: NSSegmentedControl) {
        let map: [KeyboardSettings.DelayPreset] = [.short, .normal, .long]
        guard sender.selectedSegment < map.count else { return }
        KeyboardSettings.doublePressDelayPreset = map[sender.selectedSegment]
    }

    @objc private func setAlef(_ sender: NSSegmentedControl) {
        KeyboardSettings.doubleAlefStyle = sender.selectedSegment == 0 ? .kharoZabar : .alefMadda
    }

    @objc private func setYeh(_ sender: NSSegmentedControl) {
        KeyboardSettings.urduYehStyle = sender.selectedSegment == 0 ? .arabicYeh : .farsiYeh
    }

    @objc private func setKaaf(_ sender: NSSegmentedControl) {
        KeyboardSettings.urduKaafStyle = sender.selectedSegment == 0 ? .arabicKaaf : .urduKaaf
    }

    @objc private func setHaa(_ sender: NSSegmentedControl) {
        KeyboardSettings.urduHaaStyle = sender.selectedSegment == 0 ? .arabicHaa : .heGoal
    }

    @objc private func setTaa(_ sender: NSSegmentedControl) {
        KeyboardSettings.urduTaaMarbutaStyle = sender.selectedSegment == 0 ? .arabicTaaMarbuta : .urduTaaMarbuta
    }
}
