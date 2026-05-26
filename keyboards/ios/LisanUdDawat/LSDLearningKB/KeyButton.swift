import UIKit

// Pure display component — no touch handling of its own.
// KeyboardView owns all touch logic so cross-key sliding works naturally.

final class KeyButton: UIView {

    let keyData: KeyData

    // Row position — used to vary depth-gradient intensity across rows.
    // Row 0 = top of keyboard, totalRows - 1 = bottom (function row).
    let rowIndex: Int
    let totalRows: Int

    // MARK: - Appearance

    private let label = UILabel()
    private let secondaryLabel = UILabel()  // small char in top-left; double-tap inserts it
    private let badge = UIView()            // dot indicating long-press alternates exist

    // Depth-gradient layers that simulate a forward-tilted physical key face.
    private let depthGradient = CAGradientLayer()
    private let topEdgeStrip  = CALayer()

    private var isHighlighted = false {
        didSet { applyHighlight() }
    }

    // Lazily cached — nil until first use, and can be cleared by invalidateFontCache()
    // so that a background font registration can take effect without rebuilding the keyboard.
    private static var _fatemiFont24: UIFont?
    private static var _fatemiFont10: UIFont?

    static var fatemiFont24: UIFont {
        if _fatemiFont24 == nil {
            _fatemiFont24 = UIFont(name: "FatemiMaqala-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24)
        }
        return _fatemiFont24!
    }
    static var fatemiFont10: UIFont {
        if _fatemiFont10 == nil {
            _fatemiFont10 = UIFont(name: "FatemiMaqala-Regular", size: 10) ?? UIFont.systemFont(ofSize: 10)
        }
        return _fatemiFont10!
    }

    static func invalidateFontCache() {
        _fatemiFont24 = nil
        _fatemiFont10 = nil
    }

    // Background colours — all adaptive (light/dark)
    var normalBackground: UIColor {
        switch keyData.type {
        case .character, .space:
            return KeyboardColors.characterKey
        case .backspace, .numeric, .abc, .globe, .emoji,
             .diacritic, .cursorLeft, .cursorRight, .enter,
             .latin, .shift:
            return KeyboardColors.specialKey
        }
    }
    private var pressedBackground: UIColor { KeyboardColors.pressedKey }

    // MARK: - Init

    init(keyData: KeyData, rowIndex: Int = 0, totalRows: Int = 4) {
        self.keyData   = keyData
        self.rowIndex  = rowIndex
        self.totalRows = totalRows
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupView() {
        layer.cornerRadius = 5
        layer.masksToBounds = false
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.28
        layer.shadowRadius  = 0
        layer.shadowOffset  = CGSize(width: 0, height: 1)
        backgroundColor = normalBackground

        label.text          = visibleText(keyData.primary)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        label.font = labelFont()
        label.textColor = .label
        addSubview(label)

        if !keyData.secondary.isEmpty && keyData.type == .character {
            secondaryLabel.text      = keyData.secondary
            secondaryLabel.font      = KeyButton.fatemiFont10
            secondaryLabel.textColor = .tertiaryLabel
            secondaryLabel.textAlignment = .center
            secondaryLabel.adjustsFontSizeToFitWidth = true
            secondaryLabel.minimumScaleFactor = 0.7
            addSubview(secondaryLabel)
        }

        if !keyData.alternates.isEmpty && keyData.secondary.isEmpty && keyData.type == .character {
            badge.backgroundColor = UIColor(white: 0.55, alpha: 0.6)
            badge.layer.cornerRadius = 2
            addSubview(badge)
        }

        setupDepthLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.insetBy(dx: 2, dy: 2)

        if !keyData.secondary.isEmpty && keyData.type == .character {
            secondaryLabel.frame = CGRect(x: 2, y: 2, width: 16, height: 14)
        }

        if !keyData.alternates.isEmpty && keyData.secondary.isEmpty && keyData.type == .character {
            badge.frame = CGRect(x: bounds.width - 8, y: 4, width: 4, height: 4)
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        depthGradient.frame = bounds
        topEdgeStrip.frame  = CGRect(x: 0, y: 0, width: bounds.width, height: 3)
        CATransaction.commit()
    }

    private func labelFont() -> UIFont {
        switch keyData.type {
        case .character:
            return KeyButton.fatemiFont24
        case .backspace, .enter, .cursorLeft, .cursorRight:
            return UIFont.systemFont(ofSize: 16)
        case .shift:
            return UIFont.systemFont(ofSize: 18)
        default:
            return UIFont.systemFont(ofSize: 14, weight: .medium)
        }
    }

    // Combining diacritics (non-spacing marks) are invisible without a base glyph.
    // Prepend an Arabic tatweel so they render visibly on the key face.
    private func visibleText(_ text: String) -> String {
        guard !text.isEmpty,
              text.unicodeScalars.allSatisfy({ $0.properties.generalCategory == .nonspacingMark })
        else { return text }
        return "ـ" + text
    }

    // MARK: - Public state setters

    func refreshFont() {
        label.font = labelFont()
        if !keyData.secondary.isEmpty && keyData.type == .character {
            secondaryLabel.font = KeyButton.fatemiFont10
        }
    }

    func setHighlighted(_ on: Bool) {
        guard on != isHighlighted else { return }
        isHighlighted = on
    }

    // MARK: - Private

    private func applyHighlight() {
        backgroundColor = isHighlighted ? pressedBackground : normalBackground
    }

    // MARK: - Depth layers

    private func setupDepthLayers() {
        // Gradient covers the full key face; fades from a shadow at the top to
        // transparent at ~55% of the way down.  This mimics the shadow you would see
        // on a physical key face that is tilted slightly toward the viewer.
        depthGradient.startPoint = CGPoint(x: 0.5, y: 0)
        depthGradient.endPoint   = CGPoint(x: 0.5, y: 1)
        depthGradient.locations  = [0, 0.55]
        // Rounded top corners only — the bottom fades to transparent anyway.
        depthGradient.cornerRadius    = 5
        depthGradient.maskedCorners   = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        depthGradient.masksToBounds   = true
        layer.addSublayer(depthGradient)

        // Thin strip representing the "back wall" of a physically angled key —
        // the edge that faces away from you and catches the least light.
        topEdgeStrip.cornerRadius  = 5
        topEdgeStrip.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        topEdgeStrip.masksToBounds = true
        layer.addSublayer(topEdgeStrip)

        applyDepthColors()
    }

    private func applyDepthColors() {
        let enabled = KeyboardSettings.angledKeysEnabled
        depthGradient.isHidden = !enabled
        topEdgeStrip.isHidden  = !enabled
        guard enabled else { return }

        // Top rows are physically tilted more toward the viewer on a physical
        // keyboard, so they get a slightly stronger shadow gradient.
        let fraction  = totalRows > 1 ? Double(rowIndex) / Double(totalRows - 1) : 0
        let intensity = CGFloat(0.14 - fraction * 0.06)  // 0.14 at row 0 → 0.08 at last row

        depthGradient.colors = [
            UIColor(white: 0, alpha: intensity).cgColor,
            UIColor(white: 0, alpha: 0).cgColor,
        ]

        // Strip is slightly more pronounced in dark mode where the ambient contrast
        // between key face and background is lower.
        let stripAlpha: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0.22 : 0.13
        topEdgeStrip.backgroundColor = UIColor(white: 0, alpha: stripAlpha).cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            backgroundColor = normalBackground
            applyDepthColors()
        }
    }
}
