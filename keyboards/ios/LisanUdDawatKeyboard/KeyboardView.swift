import UIKit

protocol KeyboardViewDelegate: AnyObject {
    func keyPressed(_ key: KeyData)
    func longPressAlternateSelected(_ character: String)
}

final class KeyboardView: UIView {

    // MARK: - Public

    weak var delegate: KeyboardViewDelegate?

    // MARK: - Constants

    private static let rowSpacing: CGFloat = 8
    private static let keySpacing: CGFloat = 6
    private static let sidePadding: CGFloat = 3
    private static let topPadding: CGFloat = 8
    private static let bottomPadding: CGFloat = 4
    private static let standardKeyHeight: CGFloat = 42

    // MARK: - State

    private var keyButtons: [KeyButton] = []
    private var activePopup: LongPressPopupView?
    private var activePopupSourceButton: KeyButton?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.82, alpha: 1)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configuration

    func configure(with layer: KeyboardLayer) {
        // Remove existing buttons
        keyButtons.forEach { $0.removeFromSuperview() }
        keyButtons = []

        for row in layer.rows {
            for keyData in row {
                let btn = KeyButton(keyData: keyData)
                btn.delegate = self
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

        // Collect all buttons in row order by matching against current subviews order
        let rows = groupIntoRows()
        guard !rows.isEmpty else { return }

        let sp = KeyboardView.keySpacing
        let sidePad = KeyboardView.sidePadding
        let availW = bounds.width - sidePad * 2
        let keyH = KeyboardView.standardKeyHeight

        var y = KeyboardView.topPadding

        for row in rows {
            let x = layout(row: row, y: y, availableWidth: availW, sidePad: sidePad, keyHeight: keyH)
            _ = x
            y += keyH + KeyboardView.rowSpacing
        }

        invalidateIntrinsicContentSize()
    }

    // Returns actual height so parent can constrain
    override var intrinsicContentSize: CGSize {
        let rowCount = groupIntoRows().count
        let h = KeyboardView.topPadding
            + CGFloat(rowCount) * KeyboardView.standardKeyHeight
            + CGFloat(max(0, rowCount - 1)) * KeyboardView.rowSpacing
            + KeyboardView.bottomPadding
        return CGSize(width: UIView.noIntrinsicMetric, height: h)
    }

    // MARK: - Layout helpers

    private func groupIntoRows() -> [[KeyButton]] {
        // Buttons are added in row order; re-group by matching layer rows
        var result: [[KeyButton]] = []
        var idx = 0
        for row in currentLayerRows() {
            let count = row.count
            let slice = Array(keyButtons[idx..<min(idx + count, keyButtons.count)])
            if !slice.isEmpty { result.append(slice) }
            idx += count
        }
        return result
    }

    private func currentLayerRows() -> [[KeyData]] {
        // Peek at first button to determine current layer (fragile but simple)
        guard let first = keyButtons.first else { return [] }
        switch first.keyData.primary {
        case "ض": return KeyboardLayoutData.defaultLayer.rows
        case "َ", "ُ": return KeyboardLayoutData.shiftLayer.rows
        case "1": return KeyboardLayoutData.numericLayer.rows
        default: return KeyboardLayoutData.defaultLayer.rows
        }
    }

    @discardableResult
    private func layout(
        row: [KeyButton],
        y: CGFloat,
        availableWidth: CGFloat,
        sidePad: CGFloat,
        keyHeight: CGFloat
    ) -> CGFloat {
        let sp = KeyboardView.keySpacing
        let standardW = standardKeyWidth(in: row, availableWidth: availableWidth)

        // Compute each button width
        var widths: [CGFloat] = row.map { btn in
            switch btn.keyData.width {
            case .standard:         return standardW
            case .wide:             return standardW * 1.5
            case .extraWide:        return standardW * 2.5
            case .fixed(let w):     return w
            case .flexible:         return 0 // computed below
            }
        }

        // Flexible keys fill remaining space
        let fixedTotal = widths.reduce(0, +) + CGFloat(row.count - 1) * sp
        let flexCount = CGFloat(widths.filter { $0 == 0 }.count)
        let flexW = flexCount > 0 ? (availableWidth - fixedTotal) / flexCount : 0

        widths = widths.map { $0 == 0 ? flexW : $0 }

        // Lay out left-to-right
        var x = sidePad
        for (btn, w) in zip(row, widths) {
            btn.frame = CGRect(x: x, y: y, width: w, height: keyHeight)
            x += w + sp
        }

        return x
    }

    private func standardKeyWidth(in row: [KeyButton], availableWidth: CGFloat) -> CGFloat {
        let sp = KeyboardView.keySpacing
        // Count how many standard-width slots
        var standardCount: CGFloat = 0
        var fixedUsed: CGFloat = 0
        var flexCount: CGFloat = 0

        for btn in row {
            switch btn.keyData.width {
            case .standard:             standardCount += 1
            case .wide:                 standardCount += 1.5
            case .extraWide:            standardCount += 2.5
            case .fixed(let w):         fixedUsed += w
            case .flexible:             flexCount += 1
            }
        }

        let totalSpacing = CGFloat(row.count - 1) * sp
        let availForStandard = availableWidth - fixedUsed - totalSpacing
        guard standardCount > 0 else { return 44 }
        return availForStandard / standardCount
    }
}

// MARK: - KeyButtonDelegate

extension KeyboardView: KeyButtonDelegate {

    func keyButtonTapped(_ button: KeyButton) {
        dismissPopup()
        delegate?.keyPressed(button.keyData)
    }

    func keyButtonRepeatFired(_ button: KeyButton) {
        delegate?.keyPressed(button.keyData)
    }

    func keyButtonLongPressed(_ button: KeyButton) {
        guard !button.keyData.alternates.isEmpty else { return }
        showPopup(for: button)
    }

    // MARK: - Popup management

    private func showPopup(for button: KeyButton) {
        dismissPopup()

        let popup = LongPressPopupView(
            alternates: button.keyData.alternates,
            keySize: button.bounds.size
        )
        popup.delegate = self

        // Position above the key
        var origin = button.convert(CGPoint.zero, to: self)
        origin.y -= popup.bounds.height + 4
        // Clamp to keyboard bounds
        origin.x = max(4, min(bounds.width - popup.bounds.width - 4, origin.x))

        popup.frame.origin = origin
        addSubview(popup)
        activePopup = popup
        activePopupSourceButton = button

        // Track finger movement over popup
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePopupPan(_:)))
        popup.addGestureRecognizer(pan)

        // Also watch touches on this view
        let overlay = UITapGestureRecognizer(target: self, action: #selector(dismissPopupTap))
        overlay.numberOfTapsRequired = 1
        overlay.cancelsTouchesInView = false
        addGestureRecognizer(overlay)
    }

    private func dismissPopup() {
        activePopup?.removeFromSuperview()
        activePopup = nil
        activePopupSourceButton = nil
        gestureRecognizers?.removeAll(where: { $0 is UITapGestureRecognizer })
    }

    @objc private func dismissPopupTap() { dismissPopup() }

    @objc private func handlePopupPan(_ gr: UIPanGestureRecognizer) {
        guard let popup = activePopup else { return }
        let pt = gr.location(in: popup)
        popup.updateSelection(at: pt)

        if gr.state == .ended {
            popup.confirmSelection()
            dismissPopup()
        }
    }
}

// MARK: - LongPressPopupDelegate

extension KeyboardView: LongPressPopupDelegate {
    func popupDidSelect(_ character: String) {
        delegate?.longPressAlternateSelected(character)
    }

    func popupDidCancel() {
        // No-op — already dismissed
    }
}
