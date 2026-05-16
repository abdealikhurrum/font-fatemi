import UIKit

protocol KeyButtonDelegate: AnyObject {
    func keyButtonTapped(_ button: KeyButton)
    func keyButtonLongPressed(_ button: KeyButton)
    func keyButtonRepeatFired(_ button: KeyButton)  // for held backspace
}

final class KeyButton: UIView {

    // MARK: - Public

    weak var delegate: KeyButtonDelegate?
    let keyData: KeyData

    // MARK: - Private

    private let label = UILabel()
    private var pressTimer: Timer?
    private var repeatTimer: Timer?
    private var isHighlighted = false {
        didSet { updateAppearance() }
    }

    // Colours
    private var normalBG: UIColor { keyData.type == .character ? .white : UIColor(white: 0.70, alpha: 1) }
    private var pressedBG: UIColor { UIColor(white: 0.80, alpha: 1) }
    private static let cornerRadius: CGFloat = 5

    // MARK: - Init

    init(keyData: KeyData) {
        self.keyData = keyData
        super.init(frame: .zero)
        setupView()
        setupGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = normalBG
        layer.cornerRadius = KeyButton.cornerRadius
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 0
        layer.shadowOffset = CGSize(width: 0, height: 1)

        label.text = keyData.primary
        label.textAlignment = .center
        label.font = labelFont()
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
        ])
    }

    private func labelFont() -> UIFont {
        switch keyData.type {
        case .character:
            // Use FatemiMaqala if bundled, otherwise system Arabic
            if let custom = UIFont(name: "FatemiMaqala", size: 20) { return custom }
            return UIFont.systemFont(ofSize: 20)
        case .shift, .backspace, .enter:
            return UIFont.systemFont(ofSize: 16)
        default:
            return UIFont.systemFont(ofSize: 14, weight: .medium)
        }
    }

    private func setupGestures() {
        let touch = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        touch.minimumPressDuration = 0    // we distinguish tap vs. long ourselves
        touch.cancelsTouchesInView = false
        addGestureRecognizer(touch)
    }

    // MARK: - Appearance

    private func updateAppearance() {
        UIView.animate(withDuration: 0.05) {
            self.backgroundColor = self.isHighlighted ? self.pressedBG : self.normalBG
        }
    }

    func applyActiveShiftAppearance(_ active: Bool) {
        guard keyData.type == .shift else { return }
        backgroundColor = active
            ? UIColor(white: 0.30, alpha: 1)
            : normalBG
        label.textColor = active ? .white : .label
    }

    // MARK: - Gesture

    @objc private func handleLongPress(_ gr: UILongPressGestureRecognizer) {
        switch gr.state {
        case .began:
            isHighlighted = true
            if keyData.type == .backspace {
                // Start repeat-delete after brief delay
                pressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    self.repeatTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                        guard let self else { return }
                        self.delegate?.keyButtonRepeatFired(self)
                    }
                }
            } else if !keyData.alternates.isEmpty {
                pressTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    self.delegate?.keyButtonLongPressed(self)
                }
            }

        case .ended, .cancelled:
            isHighlighted = false
            let wasPressTimerAlive = pressTimer != nil
            cancelTimers()

            // If the press timer was still alive (fired before 350ms), treat as tap
            if wasPressTimerAlive || keyData.alternates.isEmpty {
                // Gesture ended before long-press threshold — normal tap
                if gr.state == .ended {
                    delegate?.keyButtonTapped(self)
                }
            }

        default:
            break
        }
    }

    private func cancelTimers() {
        pressTimer?.invalidate()
        pressTimer = nil
        repeatTimer?.invalidate()
        repeatTimer = nil
    }
}
