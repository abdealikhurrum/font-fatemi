import UIKit

protocol PredictiveBarDelegate: AnyObject {
    func predictiveBar(_ bar: PredictiveBar, didSelect suggestion: String)
    func predictiveBarDidTapSettings(_ bar: PredictiveBar)
}

final class PredictiveBar: UIView {

    weak var delegate: PredictiveBarDelegate?

    static let height: CGFloat = 44

    private var suggestionButtons: [UIButton] = []
    private let settingsButton = UIButton(type: .system)
    private static let settingsWidth: CGFloat = 40

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardColors.predictiveBar
        buildSettingsButton()
        buildSuggestionButtons()
        addSeparators()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public

    func update(suggestions: [String]) {
        for (i, btn) in suggestionButtons.enumerated() {
            let text = i < suggestions.count ? suggestions[i] : ""
            btn.setTitle(text, for: .normal)
            btn.isEnabled = !text.isEmpty
            btn.alpha = text.isEmpty ? 0.35 : 1
        }
    }

    // MARK: - Build

    private func buildSettingsButton() {
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = .secondaryLabel
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        addSubview(settingsButton)
    }

    private func buildSuggestionButtons() {
        for i in 0..<3 {
            let btn = UIButton(type: .system)
            btn.setTitleColor(.label, for: .normal)
            btn.setTitleColor(.secondaryLabel, for: .disabled)
            btn.titleLabel?.font = i == 1
                ? UIFont.systemFont(ofSize: 15, weight: .medium)
                : UIFont.systemFont(ofSize: 15)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            btn.tag = i
            btn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            btn.addTarget(self, action: #selector(highlightBtn(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(unhighlightBtn(_:)),
                          for: [.touchUpInside, .touchUpOutside, .touchCancel])
            addSubview(btn)
            suggestionButtons.append(btn)
        }
        update(suggestions: [])
    }

    private func addSeparators() {
        for _ in 0..<3 {   // 2 between suggestions + 1 before gear
            let s = UIView()
            s.backgroundColor = KeyboardColors.separator
            addSubview(s)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height
        let suggW = (bounds.width - Self.settingsWidth) / 3

        for (i, btn) in suggestionButtons.enumerated() {
            btn.frame = CGRect(x: CGFloat(i) * suggW, y: 0, width: suggW, height: h)
        }
        settingsButton.frame = CGRect(
            x: bounds.width - Self.settingsWidth, y: 0,
            width: Self.settingsWidth, height: h)

        let seps = subviews.filter { !($0 is UIButton) }
        guard seps.count >= 3 else { return }
        seps[0].frame = CGRect(x: suggW - 0.5, y: 8, width: 1, height: h - 16)
        seps[1].frame = CGRect(x: 2 * suggW - 0.5, y: 8, width: 1, height: h - 16)
        seps[2].frame = CGRect(x: bounds.width - Self.settingsWidth - 0.5, y: 8, width: 1, height: h - 16)
    }

    // MARK: - Actions

    @objc private func suggestionTapped(_ btn: UIButton) {
        guard let text = btn.title(for: .normal), !text.isEmpty else { return }
        delegate?.predictiveBar(self, didSelect: text)
    }

    @objc private func settingsTapped() {
        delegate?.predictiveBarDidTapSettings(self)
    }

    @objc private func highlightBtn(_ btn: UIButton) {
        UIView.animate(withDuration: 0.05) { btn.backgroundColor = UIColor(white: 0.78, alpha: 1) }
    }

    @objc private func unhighlightBtn(_ btn: UIButton) {
        UIView.animate(withDuration: 0.1) { btn.backgroundColor = .clear }
    }
}
