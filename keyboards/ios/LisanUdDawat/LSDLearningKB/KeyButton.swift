import UIKit

// Pure display component — no touch handling of its own.
// KeyboardView owns all touch logic so cross-key sliding works naturally.

final class KeyButton: UIView {

    let keyData: KeyData

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
             .diacritic, .cursorLeft, .cursorRight, .enter:
            return KeyboardColors.specialKey
        }
    }
    private var pressedBackground: UIColor { KeyboardColors.pressedKey }

    // MARK: - Init

    init(keyData: KeyData) {
        self.keyData = keyData
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
}
