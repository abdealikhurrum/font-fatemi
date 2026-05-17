import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyPressed(_ key: KeyData)
    func doubleTapPressed(on key: KeyData)
    func longPressAlternateSelected(_ character: String)
    func backspaceWordPressed()
}

final class KeyboardView: UIView {

    weak var delegate: KeyboardViewDelegate?

    // MARK: - Layout constants

    private static let rowSpacing:     CGFloat = 12
    private static let keySpacing:     CGFloat = 6
    private static let sidePadding:    CGFloat = 3
    private static let topPadding:     CGFloat = 12
    private static let bottomPadding:  CGFloat = 5
    private static let standardKeyH:   CGFloat = 46
    // Extra transparent space at the top of the keyboard view so callout bubbles
    // for top-row keys remain within the view's bounds and are never clipped.
    private static let calloutOverflow: CGFloat = 44

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
    private static let doubleTapWindow: TimeInterval = 0.35

    // MARK: - Callout

    private var calloutView: KeyCalloutView?

    // MARK: - Popup (long-press alternates)

    private var activePopup: LongPressPopupView?
    private var popupSourceKey: KeyButton?

    // MARK: - Keys

    private var keyButtons: [KeyButton] = []
    private var currentRows: [[KeyData]] = []

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardColors.background
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with layer: KeyboardLayer) {
        keyButtons.forEach { $0.removeFromSuperview() }
        keyButtons = []
        currentRows = layer.rows
        lastTappedKey = nil
        lastTapTime = nil

        for row in layer.rows {
            for keyData in row {
                let btn = KeyButton(keyData: keyData)
                addSubview(btn)
                keyButtons.append(btn)
            }
        }
        setNeedsLayout()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !keyButtons.isEmpty else { return }

        let rows    = groupedRows()
        let sidePad = KeyboardView.sidePadding
        let availW  = bounds.width - sidePad * 2
        let keyH    = KeyboardView.standardKeyH
        // Keys start below the callout overflow zone
        var y       = KeyboardView.calloutOverflow + KeyboardView.topPadding

        for row in rows {
            layoutRow(row, y: y, availableWidth: availW, sidePad: sidePad, keyH: keyH)
            y += keyH + KeyboardView.rowSpacing
        }
    }

    override var intrinsicContentSize: CGSize {
        let n = CGFloat(currentRows.count)
        let h = KeyboardView.calloutOverflow
            + KeyboardView.topPadding
            + n * KeyboardView.standardKeyH
            + max(0, n - 1) * KeyboardView.rowSpacing
            + KeyboardView.bottomPadding
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

        // If popup is open, route movement into it
        if let popup = activePopup {
            popup.updateSelection(at: touch.location(in: popup))
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
            popup.confirmSelection()
            dismissPopup()
            return
        }

        cancelTimers()
        dismissCallout()

        guard let key = activeKey else { return }
        key.setHighlighted(false)
        activeKey = nil

        // Double-tap: same character key, non-empty secondary, within window
        let isDouble = key === lastTappedKey
            && key.keyData.type == .character
            && !key.keyData.secondary.isEmpty
            && lastTapTime.map { Date().timeIntervalSince($0) < Self.doubleTapWindow } == true

        if isDouble {
            lastTappedKey = nil
            lastTapTime   = nil
            delegate?.doubleTapPressed(on: key.keyData)
        } else {
            lastTappedKey = key.keyData.type == .character ? key : nil
            lastTapTime   = key.keyData.type == .character ? Date() : nil
            delegate?.keyPressed(key.keyData)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelTimers()
        dismissCallout()
        dismissPopup()
        activeKey?.setHighlighted(false)
        activeKey = nil
    }

    // MARK: - Activation

    private func activate(key: KeyButton, touch: UITouch) {
        activeKey = key
        key.setHighlighted(true)

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

        // Long press for alternates
        if !key.keyData.alternates.isEmpty {
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                guard let self else { return }
                self.dismissCallout()
                self.showPopup(for: key)
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
        activePopup?.removeFromSuperview()
        activePopup    = nil
        popupSourceKey = nil
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
    }

    // MARK: - Hit testing

    // Returns the key whose center is nearest to the touch point (Voronoi approach).
    // Vertical distance is weighted down so row-boundary touches favour the closer
    // key face rather than empty space between rows.
    private func keyButton(at point: CGPoint) -> KeyButton? {
        guard !keyButtons.isEmpty else { return nil }
        // Must be within the overall keyboard content area (below callout overflow zone)
        guard point.y >= KeyboardView.calloutOverflow else { return nil }
        var best: KeyButton?
        var bestDist = CGFloat.infinity
        for btn in keyButtons {
            let cx = btn.frame.midX
            let cy = btn.frame.midY
            let dx = point.x - cx
            let dy = (point.y - cy) * 0.6   // compress vertical so wide keys win ties
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
