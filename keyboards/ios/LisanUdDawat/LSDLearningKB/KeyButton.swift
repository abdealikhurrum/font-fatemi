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

    // Background colours — all adaptive (light/dark)
    var normalBackground: UIColor {
        switch keyData.type {
        case .character, .space:                    return KeyboardColors.characterKey
        case .backspace, .numeric, .abc,
             .globe, .enter:                        return KeyboardColors.specialKey
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
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor,   constant: 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            label.topAnchor.constraint(equalTo: topAnchor,           constant: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor,     constant: -2),
        ])

        // Secondary char — top-left corner, shown when double-tap is available
        if !keyData.secondary.isEmpty && keyData.type == .character {
            secondaryLabel.text      = keyData.secondary
            secondaryLabel.font      = UIFont(name: "FatemiMaqala", size: 10) ?? UIFont.systemFont(ofSize: 10)
            secondaryLabel.textColor = .tertiaryLabel
            secondaryLabel.textAlignment = .center
            secondaryLabel.adjustsFontSizeToFitWidth = true
            secondaryLabel.minimumScaleFactor = 0.7
            secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
            addSubview(secondaryLabel)
            NSLayoutConstraint.activate([
                secondaryLabel.topAnchor.constraint(equalTo: topAnchor, constant: 2),
                secondaryLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 2),
                secondaryLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 16),
            ])
        }

        // Tiny dot when long-press alternates exist but no secondary is shown
        if !keyData.alternates.isEmpty && keyData.secondary.isEmpty && keyData.type == .character {
            badge.backgroundColor = UIColor(white: 0.55, alpha: 0.6)
            badge.layer.cornerRadius = 2
            badge.translatesAutoresizingMaskIntoConstraints = false
            addSubview(badge)
            NSLayoutConstraint.activate([
                badge.topAnchor.constraint(equalTo: topAnchor, constant: 4),
                badge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
                badge.widthAnchor.constraint(equalToConstant: 4),
                badge.heightAnchor.constraint(equalToConstant: 4),
            ])
        }
    }

    private func labelFont() -> UIFont {
        switch keyData.type {
        case .character:
            return UIFont(name: "FatemiMaqala", size: 24) ?? UIFont.systemFont(ofSize: 24)
        case .backspace, .enter:
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

    func setHighlighted(_ on: Bool) {
        guard on != isHighlighted else { return }
        isHighlighted = on
    }

    // MARK: - Private

    private func applyHighlight() {
        backgroundColor = isHighlighted ? pressedBackground : normalBackground
    }
}
