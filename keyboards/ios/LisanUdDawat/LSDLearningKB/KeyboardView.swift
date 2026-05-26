import UIKit

// Sizing constants that vary between portrait and landscape.
struct KeyboardMetrics {
    let keyH: CGFloat
    let rowSpacing: CGFloat
    let topPadding: CGFloat
    let bottomPadding: CGFloat
    let calloutOverflow: CGFloat  // transparent headroom so top-row callouts are never clipped
    let barHeight: CGFloat        // predictive/suggestion bar

    static let portrait = KeyboardMetrics(
        keyH: 46, rowSpacing: 12, topPadding: 12, bottomPadding: 5, calloutOverflow: 0, barHeight: 44
    )
    // Shorter keys + tighter spacing free up screen real-estate in landscape.
    static let landscape = KeyboardMetrics(
        keyH: 34, rowSpacing: 8, topPadding: 6, bottomPadding: 4, calloutOverflow: 0, barHeight: 36
    )
}

protocol KeyboardViewDelegate: AnyObject {
    func keyPressed(_ key: KeyData)
    func doubleTapPressed(on key: KeyData)
    func longPressAlternateSelected(_ character: String)
    func backspaceWordPressed()
    func keyTapped(_ key: KeyData, touchOffset: CGPoint)
}

final class KeyboardView: UIView {

    weak var delegate: KeyboardViewDelegate?

    // MARK: - Layout constants

    // These two are screen-width-independent and don't change with orientation.
    private static let keySpacing:  CGFloat = 6
    private static let sidePadding: CGFloat = 3

    // Orientation-sensitive metrics; updated by KeyboardViewController on rotation.
    var metrics: KeyboardMetrics = .portrait {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    // MARK: - Touch tracking
    // All touch logic lives here — gives us cross-key sliding for free.

    private var activeKey: KeyButton?
    private var longPressTimer: Timer?
    private var backspaceRepeatTimer: Timer?
    private var backspaceInitialTimer: Timer?
    private var backspaceDeleteCount = 0

    // Double-tap tracking
    private var lastTappedKey: KeyButton?
    private var lastTapTime: Date?
    private var doubleTapWindow: TimeInterval { KeyboardSettings.doubleTapDelay }

    // Touch offset tracking — record where the finger first lands (touchesBegan)
    private var activeTouchBeganPoint: CGPoint?

    // MARK: - Callout

    private var calloutView: KeyCalloutView?

    // MARK: - Popup (long-press alternates)

    private var activePopup: LongPressPopupView?
    private var popupSourceKey: KeyButton?
    private var popupRepeatInitialTimer: Timer?
    private var popupRepeatTimer: Timer?
    private var popupRepeatFired = false

    // Held-key repeat for base character keys
    private var keyRepeatInitialTimer: Timer?
    private var keyRepeatTimer: Timer?
    private var keyRepeatFired = false

    // MARK: - Keys

    private var keyButtons: [KeyButton] = []
    private var currentRows: [[KeyData]] = []

    // MARK: - Haptic

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardColors.background
        feedbackGenerator.prepare()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with layer: KeyboardLayer) {
        keyButtons.forEach { $0.removeFromSuperview() }
        keyButtons = []
        currentRows = layer.rows
        lastTappedKey = nil
        lastTapTime = nil

        for (rowIdx, row) in layer.rows.enumerated() {
            for keyData in row {
                let btn = KeyButton(keyData: keyData, rowIndex: rowIdx, totalRows: layer.rows.count)
                addSubview(btn)
                keyButtons.append(btn)
            }
        }
        setNeedsLayout()
    }

    func refreshKeyFonts() {
        keyButtons.forEach { $0.refreshFont() }
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !keyButtons.isEmpty else { return }

        let m       = metrics
        let rows    = groupedRows()
        let sidePad = KeyboardView.sidePadding
        let availW  = bounds.width - sidePad * 2
        let keyH    = m.keyH
        var y       = m.calloutOverflow + m.topPadding

        for row in rows {
            layoutRow(row, y: y, availableWidth: availW, sidePad: sidePad, keyH: keyH)
            y += keyH + m.rowSpacing
        }
    }

    override var intrinsicContentSize: CGSize {
        let m = metrics
        let n = CGFloat(currentRows.count)
        let h = m.calloutOverflow
            + m.topPadding
            + n * m.keyH
            + max(0, n - 1) * m.rowSpacing
            + m.bottomPadding
        return CGSize(width: UIView.noIntrinsicMetric, height: h)
    }

    // MARK: - Touch handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if let key = keyButton(at: touch.location(in: self)) {
            activate(key: key, touch: touch)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        // If popup is open, route movement into it and manage repeat timer
        if let popup = activePopup {
            let prevChar = popup.selectedCharacter
            popup.updateSelection(at: touch.location(in: popup))
            let newChar  = popup.selectedCharacter
            if newChar != prevChar {
                cancelPopupRepeatTimers()
                popupRepeatFired = false
                if newChar != nil { schedulePopupRepeat() }
            } else if newChar != nil, popupRepeatInitialTimer == nil, popupRepeatTimer == nil {
                schedulePopupRepeat()
            }
            return
        }

        let pt = touch.location(in: self)
        guard let newKey = keyButton(at: pt), newKey !== activeKey else { return }

        // Slid to a different key
        cancelTimers()
        dismissCallout()
        activeKey?.setHighlighted(false)

        activate(key: newKey, touch: touch)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let popup = activePopup {
            if !popupRepeatFired { popup.confirmSelection() }
            dismissPopup()
            return
        }

        cancelTimers()
        dismissCallout()

        guard let key = activeKey else { return }
        key.setHighlighted(false)
        activeKey = nil

        // Held repeat was running — finger-up just stops it, no extra tap event
        if keyRepeatFired {
            keyRepeatFired = false
            return
        }

        // Double-tap: same character key, non-empty secondary, within window
        let isDouble = key === lastTappedKey
            && key.keyData.type == .character
            && !key.keyData.secondary.isEmpty
            && lastTapTime.map { Date().timeIntervalSince($0) < doubleTapWindow } == true

        if isDouble {
            lastTappedKey         = nil
            lastTapTime           = nil
            activeTouchBeganPoint = nil
            delegate?.doubleTapPressed(on: key.keyData)
        } else {
            lastTappedKey = key.keyData.type == .character ? key : nil
            lastTapTime   = key.keyData.type == .character ? Date() : nil
            if key.keyData.type == .character, let pt = activeTouchBeganPoint {
                let offset = CGPoint(x: pt.x - key.frame.midX, y: pt.y - key.frame.midY)
                delegate?.keyTapped(key.keyData, touchOffset: offset)
            }
            activeTouchBeganPoint = nil
            delegate?.keyPressed(key.keyData)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelTimers()
        dismissCallout()
        dismissPopup()
        activeKey?.setHighlighted(false)
        activeKey             = nil
        activeTouchBeganPoint = nil
    }

    // MARK: - Activation

    private func activate(key: KeyButton, touch: UITouch) {
        activeKey = key
        activeTouchBeganPoint = touch.location(in: self)
        key.setHighlighted(true)
        feedbackGenerator.impactOccurred()

        // Show callout for regular character keys (not special keys)
        if key.keyData.type == .character && !key.keyData.primary.isEmpty {
            showCallout(for: key)
        }

        // Backspace: fire once, then start accelerating repeat
        if key.keyData.type == .backspace {
            backspaceInitialTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.startBackspaceRepeat()
            }
            return
        }

        let lpDelay = KeyboardSettings.longPressDelay

        // Long-press for character keys: show popup (if alternates exist) then fall through to repeat
        if key.keyData.type == .character {
            longPressTimer = Timer.scheduledTimer(withTimeInterval: lpDelay, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.dismissCallout()
                if !key.keyData.alternates.isEmpty {
                    self.showPopup(for: key)
                    // Popup times out → key repeat after another 0.8s if nothing selected
                    self.scheduleKeyRepeat(for: key, delay: 0.8)
                } else {
                    self.startKeyRepeat(for: key)
                }
            }
        } else if !key.keyData.alternates.isEmpty {
            // Non-character keys with alternates (space bar) — popup only, no base repeat
            longPressTimer = Timer.scheduledTimer(withTimeInterval: lpDelay, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.showPopup(for: key)
            }
        } else if let lpt = key.keyData.longPressType {
            // Keys with a long-press action (e.g. AaBb → globe, ع → globe)
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.dismissCallout()
                key.setHighlighted(false)
                self.activeKey = nil
                self.delegate?.keyPressed(KeyData("", type: lpt))
            }
        }
    }

    // MARK: - Callout

    private func showCallout(for key: KeyButton) {
        dismissCallout()
        // calloutOverflow reserves space above the keys inside this view, so the
        // callout frame stays within self's bounds — no escape to window needed.
        let keyFrameInSelf = key.convert(key.bounds, to: self)
        let cv = KeyCalloutView(
            character: key.keyData.primary,
            keyFrame:  keyFrameInSelf,
            in:        self
        )
        addSubview(cv)
        calloutView = cv
    }

    private func dismissCallout() {
        calloutView?.removeFromSuperview()
        calloutView = nil
    }

    // MARK: - Popup (alternates)

    private func showPopup(for key: KeyButton) {
        dismissPopup()
        let popup = LongPressPopupView(
            alternates: key.keyData.alternates,
            keySize:    key.bounds.size
        )
        popup.delegate = self

        var origin = key.convert(CGPoint.zero, to: self)
        origin.y -= popup.bounds.height + 4
        origin.x = max(4, min(bounds.width - popup.bounds.width - 4, origin.x))
        popup.frame.origin = origin
        addSubview(popup)
        activePopup   = popup
        popupSourceKey = key
    }

    private func dismissPopup() {
        cancelPopupRepeatTimers()
        cancelKeyRepeatTimers()
        popupRepeatFired = false
        activePopup?.removeFromSuperview()
        activePopup    = nil
        popupSourceKey = nil
    }

    // After popup shows, if nothing is selected for `delay` seconds, dismiss popup and repeat base key.
    private func scheduleKeyRepeat(for key: KeyButton, delay: TimeInterval) {
        keyRepeatInitialTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self, self.activePopup?.selectedCharacter == nil else { return }
            self.dismissPopup()
            self.startKeyRepeat(for: key)
        }
    }

    // Insert the primary character once immediately, then keep inserting every 0.08s.
    private func startKeyRepeat(for key: KeyButton) {
        keyRepeatFired = true
        delegate?.keyPressed(key.keyData)
        keyRepeatTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            self?.delegate?.keyPressed(key.keyData)
        }
    }

    private func cancelKeyRepeatTimers() {
        keyRepeatInitialTimer?.invalidate(); keyRepeatInitialTimer = nil
        keyRepeatTimer?.invalidate();        keyRepeatTimer = nil
    }

    // After the user holds on a popup item for 0.5s, insert it once, then keep
    // inserting every `popupRepeatInterval` until the finger lifts.
    // If the interval is 0, repeat is disabled.
    private func schedulePopupRepeat() {
        let interval = KeyboardSettings.popupRepeatInterval
        guard interval > 0 else { return }
        popupRepeatInitialTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            guard let self, let char = self.activePopup?.selectedCharacter else { return }
            self.popupRepeatFired = true
            self.delegate?.longPressAlternateSelected(char)
            self.popupRepeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let self, let c = self.activePopup?.selectedCharacter else {
                    self?.cancelPopupRepeatTimers()
                    return
                }
                self.delegate?.longPressAlternateSelected(c)
            }
        }
    }

    private func cancelPopupRepeatTimers() {
        popupRepeatInitialTimer?.invalidate(); popupRepeatInitialTimer = nil
        popupRepeatTimer?.invalidate();        popupRepeatTimer = nil
    }

    // MARK: - Backspace repeat
    // Phase 1 (char-by-char at 0.075s): fires for first 10 deletes
    // Phase 2 (word-by-word at 0.35s): kicks in after phase 1

    private func startBackspaceRepeat() {
        backspaceDeleteCount = 0
        backspaceRepeatTimer = Timer.scheduledTimer(withTimeInterval: 0.075, repeats: true) { [weak self] _ in
            guard let self, let key = self.activeKey else { return }
            self.backspaceDeleteCount += 1
            if self.backspaceDeleteCount > 10 {
                self.backspaceRepeatTimer?.invalidate()
                self.backspaceRepeatTimer = nil
                self.startWordRepeat()
            } else {
                self.delegate?.keyPressed(key.keyData)
            }
        }
    }

    private func startWordRepeat() {
        backspaceRepeatTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            guard let self, self.activeKey != nil else { return }
            self.delegate?.backspaceWordPressed()
        }
    }

    // MARK: - Timers

    private func cancelTimers() {
        longPressTimer?.invalidate();          longPressTimer = nil
        backspaceRepeatTimer?.invalidate();    backspaceRepeatTimer = nil
        backspaceInitialTimer?.invalidate();   backspaceInitialTimer = nil
        cancelPopupRepeatTimers()
        cancelKeyRepeatTimers()
    }

    // MARK: - Hit testing

    // Phase 1: any key whose frame (+ 3 pt inset) contains the point wins immediately.
    // This ensures wide keys like the space bar always fire when touched within their
    // visible bounds, regardless of nearby key centers.
    // Phase 2: for touches in the gaps between keys, fall back to nearest-key-center
    // with vertical distance compressed — row-boundary misses resolve to the closer row.
    private func keyButton(at point: CGPoint) -> KeyButton? {
        guard !keyButtons.isEmpty else { return nil }
        guard point.y >= metrics.calloutOverflow else { return nil }

        if let direct = keyButtons.first(where: { $0.frame.insetBy(dx: -3, dy: -3).contains(point) }) {
            return direct
        }

        var best: KeyButton?
        var bestDist = CGFloat.infinity
        for btn in keyButtons {
            let dx = point.x - btn.frame.midX
            let dy = (point.y - btn.frame.midY) * 0.6
            let dist = dx * dx + dy * dy
            if dist < bestDist {
                bestDist = dist
                best = btn
            }
        }
        return best
    }

    // MARK: - Layout helpers

    private func groupedRows() -> [[KeyButton]] {
        var result: [[KeyButton]] = []
        var idx = 0
        for row in currentRows {
            let slice = Array(keyButtons[idx..<min(idx + row.count, keyButtons.count)])
            if !slice.isEmpty { result.append(slice) }
            idx += row.count
        }
        return result
    }

    private func layoutRow(
        _ row: [KeyButton],
        y: CGFloat,
        availableWidth: CGFloat,
        sidePad: CGFloat,
        keyH: CGFloat
    ) {
        let sp = KeyboardView.keySpacing
        let stdW = standardKeyWidth(in: row, availableWidth: availableWidth)

        var widths: [CGFloat] = row.map { btn in
            switch btn.keyData.width {
            case .standard:        return stdW
            case .wide:            return stdW * 1.5
            case .extraWide:       return stdW * 2.5
            case .fixed(let w):    return w
            case .flexible:        return 0
            }
        }

        let fixedTotal = widths.reduce(0, +) + CGFloat(row.count - 1) * sp
        let flexCount  = CGFloat(widths.filter { $0 == 0 }.count)
        let flexW      = flexCount > 0 ? (availableWidth - fixedTotal) / flexCount : 0
        widths = widths.map { $0 == 0 ? flexW : $0 }

        var x = sidePad
        for (btn, w) in zip(row, widths) {
            btn.frame = CGRect(x: x, y: y, width: w, height: keyH)
            x += w + sp
        }
    }

    private func standardKeyWidth(in row: [KeyButton], availableWidth: CGFloat) -> CGFloat {
        let sp = KeyboardView.keySpacing
        var slots: CGFloat = 0
        var fixedUsed: CGFloat = 0

        for btn in row {
            switch btn.keyData.width {
            case .standard:        slots += 1
            case .wide:            slots += 1.5
            case .extraWide:       slots += 2.5
            case .fixed(let w):    fixedUsed += w
            case .flexible:        break
            }
        }

        let totalSpacing = CGFloat(row.count - 1) * sp
        guard slots > 0 else { return 44 }
        return (availableWidth - fixedUsed - totalSpacing) / slots
    }
}

// MARK: - LongPressPopupDelegate

extension KeyboardView: LongPressPopupDelegate {
    func popupDidSelect(_ character: String) {
        delegate?.longPressAlternateSelected(character)
    }
    func popupDidCancel() {}
}
