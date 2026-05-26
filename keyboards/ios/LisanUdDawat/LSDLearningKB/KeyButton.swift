import UIKit

// Pure display component — no touch handling of its own.
// KeyboardView owns all touch logic so cross-key sliding works naturally.

final class KeyButton: UIView {

    let keyData: KeyData

    // Row position — used to vary depth-gradient intensity across rows.
    // Row 0 = top of keyboard, totalRows - 1 = bottom (function row).
    let rowIndex: Int
    let totalRows: Int

    // Column position within the row — drives the left/right thumb shadow corner.
    // Col 0 = leftmost visible key, totalCols - 1 = rightmost.
    let colIndex:  Int
    let totalCols: Int

    // MARK: - Appearance

    private let label = UILabel()
    private let secondaryLabel = UILabel()  // small char in top-left; double-tap inserts it
    private let badge = UIView()            // dot indicating long-press alternates exist

    // Radial gradient that simulates a forward-tilted physical key face.
    private let depthGradient = CAGradientLayer()

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

    init(keyData: KeyData, rowIndex: Int = 0, totalRows: Int = 4, colIndex: Int = 0, totalCols: Int = 1) {
        self.keyData   = keyData
        self.rowIndex  = rowIndex
        self.totalRows = totalRows
        self.colIndex  = colIndex
        self.totalCols = totalCols
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
        depthGradient.type          = .radial
        depthGradient.cornerRadius  = 5
        depthGradient.masksToBounds = true
        layer.addSublayer(depthGradient)
        applyDepthColors()
    }

    private func applyDepthColors() {
        let enabled = KeyboardSettings.angledKeysEnabled
        depthGradient.isHidden = !enabled
        guard enabled else { return }

        // Normalised horizontal position: 0 = leftmost key, 1 = rightmost.
        let nc = totalCols > 1 ? Double(colIndex) / Double(totalCols - 1) : 0.5

        // Shadow corner: left-thumb keys shadow upper-right; right-thumb keys shadow
        // upper-left; centre keys shadow top-centre.  The gradient radiates outward
        // from that corner to the diagonally opposite (highlight) corner.
        let shadowX = CGFloat(1 - nc)
        depthGradient.startPoint = CGPoint(x: shadowX,     y: 0)
        depthGradient.endPoint   = CGPoint(x: 1 - shadowX, y: 1)

        // Upper rows tilt more steeply toward the viewer on a curved physical keyboard.
        let rowFraction = totalRows > 1 ? Double(rowIndex) / Double(totalRows - 1) : 0
        let intensity   = CGFloat(0.20 - rowFraction * 0.08)  // 0.20 top row → 0.12 bottom

        depthGradient.colors    = [UIColor(white: 0, alpha: intensity).cgColor,
                                    UIColor(white: 0, alpha: 0).cgColor]
        depthGradient.locations = [0, 1]
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            backgroundColor = normalBackground
            // CGColor values don't resolve dynamically — recompute on mode switch.
            applyDepthColors()
        }
    }
}
