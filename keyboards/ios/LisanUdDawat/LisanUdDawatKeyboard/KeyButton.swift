import UIKit

// Pure display component — no touch handling of its own.
// KeyboardView owns all touch logic so cross-key sliding works naturally.

final class KeyButton: UIView {

    let keyData: KeyData

    // MARK: - Appearance

    private let label = UILabel()
    private let badge = UIView()   // small dot indicating alternates exist

    private var isHighlighted = false {
        didSet { applyHighlight() }
    }

    // Background colours
    var normalBackground: UIColor {
        switch keyData.type {
        case .character:            return .white
        case .shift, .backspace,
             .numeric, .abc, .globe: return UIColor(white: 0.67, alpha: 1)
        case .space:                return .white
        case .enter:                return UIColor(white: 0.67, alpha: 1)
        }
    }
    private var pressedBackground: UIColor { UIColor(white: 0.82, alpha: 1) }

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

        label.text          = keyData.primary
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

        // Tiny dot in top-right corner when alternates exist
        if !keyData.alternates.isEmpty && keyData.type == .character {
            badge.backgroundColor = UIColor(white: 0.65, alpha: 1)
            badge.layer.cornerRadius = 2
            badge.frame = CGRect(x: 0, y: 0, width: 4, height: 4)
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
            if let custom = UIFont(name: "FatemiMaqala", size: 20) { return custom }
            return UIFont.systemFont(ofSize: 20)
        case .shift, .backspace, .enter:
            return UIFont.systemFont(ofSize: 16)
        default:
            return UIFont.systemFont(ofSize: 14, weight: .medium)
        }
    }

    // MARK: - Public state setters

    func setHighlighted(_ on: Bool) {
        guard on != isHighlighted else { return }
        isHighlighted = on
    }

    // Shift key — visually indicates active state
    func setShiftActive(_ active: Bool, locked: Bool = false) {
        guard keyData.type == .shift else { return }
        if locked {
            backgroundColor = UIColor(white: 0.22, alpha: 1)
            label.textColor = .white
        } else if active {
            backgroundColor = .white
            label.textColor = .label
        } else {
            backgroundColor = normalBackground
            label.textColor = .label
        }
    }

    // MARK: - Private

    private func applyHighlight() {
        // Immediate — no animation. Delay here is one of the main "off" feelings.
        backgroundColor = isHighlighted ? pressedBackground : normalBackground
    }
}
