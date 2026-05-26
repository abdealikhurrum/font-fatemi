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

        // Redraw pyramid facets when bounds change (rotation etc.)
        contentMode = .redraw
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

    // MARK: - Pyramid facets

    // Four flat triangles meeting at the key centre, drawn as semi-transparent black
    // overlays on top of the base background colour.  Each facet has a constant shade,
    // so the seam lines between them are sharp — the "pyramidal key" look.
    //
    // Facet shading model (black overlay alpha):
    //   top    — always darkest: the face that points away from the viewer
    //   bottom — always zero:    the face pointing toward the viewer (highlight)
    //   left   — scales with column: 0 for leftmost key (toward left thumb), max for rightmost
    //   right  — inverse:            max for leftmost key, 0 for rightmost key
    //
    // Upper rows receive stronger shading to reflect the steeper physical tilt of
    // keys that sit higher on a curved keyboard body.

    override func draw(_ rect: CGRect) {
        guard KeyboardSettings.angledKeysEnabled else { return }
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        // Clip to the rounded key shape so facet corners don't bleed outside.
        UIBezierPath(roundedRect: rect, cornerRadius: 5).addClip()

        let nc          = totalCols > 1 ? CGFloat(colIndex) / CGFloat(totalCols - 1) : 0.5
        let rowFraction = totalRows > 1 ? CGFloat(rowIndex) / CGFloat(totalRows - 1) : 0
        let base        = CGFloat(0.18 - Double(rowFraction) * 0.06) // 0.18 → 0.12

        let tl = CGPoint(x: rect.minX, y: rect.minY)
        let tr = CGPoint(x: rect.maxX, y: rect.minY)
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let bl = CGPoint(x: rect.minX, y: rect.maxY)
        let c  = CGPoint(x: rect.midX, y: rect.midY)

        // (corner-a, corner-b, overlay-alpha) — triangle is c → a → b
        let facets: [(CGPoint, CGPoint, CGFloat)] = [
            (tl, tr, base),              // top face:   always shadowed
            (tr, br, base * (1 - nc)),   // right face: bright for right-thumb keys
            (br, bl, 0),                 // bottom face: highlight, never darkened
            (bl, tl, base * nc),         // left face:  bright for left-thumb keys
        ]

        for (a, b, alpha) in facets {
            ctx.setFillColor(UIColor(white: 0, alpha: alpha).cgColor)
            ctx.beginPath()
            ctx.move(to: c)
            ctx.addLine(to: a)
            ctx.addLine(to: b)
            ctx.closePath()
            ctx.fillPath()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            backgroundColor = normalBackground
            setNeedsDisplay()
        }
    }
}
