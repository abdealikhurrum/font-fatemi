import UIKit

protocol PredictiveBarDelegate: AnyObject {
    func predictiveBar(_ bar: PredictiveBar, didSelect suggestion: String)
    func predictiveBarDidTapSettings(_ bar: PredictiveBar)
    func predictiveBarDidTapBiDi(_ bar: PredictiveBar, issue: BiDiAnalyzer.Issue)
}

final class PredictiveBar: UIView {

    weak var delegate: PredictiveBarDelegate?

    static let height: CGFloat = 44
    private static let settingsWidth: CGFloat = 40
    private static let biDiWidth:     CGFloat = 52

    private var suggestionButtons: [UIButton] = []
    private let settingsButton  = UIButton(type: .system)
    private let biDiButton      = BiDiFixView()
    private let biDiSeparator   = UIView()
    private var currentIssue:   BiDiAnalyzer.Issue?

    // Overlay label used for brief toast messages and the first-run BiDi tip.
    private let tooltipLabel = UILabel()
    private var tooltipTimer: Timer?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardColors.predictiveBar
        buildSettingsButton()
        buildBiDiButton()
        buildSuggestionButtons()
        addSeparators()
        buildTooltipLabel()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public

    func update(suggestions: [String]) {
        guard tooltipLabel.alpha == 0 else { return }
        for (i, btn) in suggestionButtons.enumerated() {
            let text = i < suggestions.count ? suggestions[i] : ""
            btn.setTitle(text, for: .normal)
            btn.isEnabled = !text.isEmpty
            btn.alpha = text.isEmpty ? 0.35 : 1
        }
    }

    func updateBiDi(_ text: String) {
        let issue = BiDiAnalyzer.analyze(text)
        let wasNil = currentIssue == nil
        currentIssue = issue
        biDiButton.setIssue(issue)
        biDiSeparator.isHidden = (issue == nil)

        if issue != nil && wasNil && !KeyboardSettings.biDiTooltipShown {
            KeyboardSettings.biDiTooltipShown = true
            showFirstRunBiDiTooltip()
        }

        setNeedsLayout()
    }

    func showBriefMessage(_ message: String, duration: TimeInterval = 2.0) {
        tooltipTimer?.invalidate()
        tooltipLabel.text  = message
        tooltipLabel.alpha = 0
        tooltipLabel.isHidden = false
        UIView.animate(withDuration: 0.15) { self.tooltipLabel.alpha = 1 }
        tooltipTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            UIView.animate(withDuration: 0.2) { self?.tooltipLabel.alpha = 0 } completion: { _ in
                self?.tooltipLabel.isHidden = true
            }
        }
    }

    // MARK: - Build

    private func buildSettingsButton() {
        settingsButton.setImage(UIImage(systemName: "gearshape"), for: .normal)
        settingsButton.tintColor = .secondaryLabel
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        addSubview(settingsButton)
    }

    private func buildBiDiButton() {
        biDiSeparator.backgroundColor = KeyboardColors.separator
        biDiSeparator.isHidden = true
        addSubview(biDiSeparator)

        biDiButton.isHidden = false
        biDiButton.onTap = { [weak self] in
            guard let self, let issue = self.currentIssue else { return }
            self.delegate?.predictiveBarDidTapBiDi(self, issue: issue)
        }
        addSubview(biDiButton)
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

    private func buildTooltipLabel() {
        tooltipLabel.font = .systemFont(ofSize: 13)
        tooltipLabel.textAlignment = .center
        tooltipLabel.textColor = .label
        tooltipLabel.alpha = 0
        tooltipLabel.isHidden = true
        tooltipLabel.adjustsFontSizeToFitWidth = true
        tooltipLabel.minimumScaleFactor = 0.8
        addSubview(tooltipLabel)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = bounds.height

        let biDiVisible = (currentIssue != nil)
        let biDiTotalW  = biDiVisible ? Self.biDiWidth + 1 : 0   // button + separator

        let suggTotalW = bounds.width - Self.settingsWidth - 1 - biDiTotalW
        let suggW = suggTotalW / 3

        // Suggestion buttons (left side)
        for (i, btn) in suggestionButtons.enumerated() {
            btn.frame = CGRect(x: CGFloat(i) * suggW, y: 0, width: suggW, height: h)
        }

        // BiDi separator + button (right of suggestions, left of gear)
        let biDiSepX = suggTotalW
        let biDiX    = biDiSepX + 1
        biDiSeparator.frame = CGRect(x: biDiSepX, y: 8, width: 1, height: h - 16)
        biDiButton.frame    = CGRect(x: biDiX,    y: 0, width: biDiVisible ? Self.biDiWidth : 0, height: h)

        // Gear separator + button (rightmost)
        let gearSepX = bounds.width - Self.settingsWidth - 1
        let gearX    = gearSepX + 1
        settingsButton.frame = CGRect(x: gearX, y: 0, width: Self.settingsWidth, height: h)

        // Separators between suggestion buttons + before gear
        let separators = subviews.filter { !($0 is UIButton) && !($0 is BiDiFixView) && $0 != biDiSeparator && $0 != tooltipLabel }
        if separators.count >= 3 {
            separators[0].frame = CGRect(x: suggW - 0.5,     y: 8, width: 1, height: h - 16)
            separators[1].frame = CGRect(x: 2 * suggW - 0.5, y: 8, width: 1, height: h - 16)
            separators[2].frame = CGRect(x: gearSepX,        y: 8, width: 1, height: h - 16)
        }

        // Tooltip overlay covers the full suggestion area
        tooltipLabel.frame = CGRect(x: 0, y: 0, width: suggTotalW, height: h)
    }

    // MARK: - First-run BiDi tooltip

    private func showFirstRunBiDiTooltip() {
        let message = "Tap اA to fix mixed text"
        let attributed = NSMutableAttributedString(string: message,
            attributes: [.foregroundColor: UIColor.label,
                         .font: UIFont.systemFont(ofSize: 13)])
        if let range = message.range(of: "اA") {
            let ns = NSRange(range, in: message)
            let accent = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)
            attributed.addAttribute(.foregroundColor, value: accent, range: ns)
        }
        tooltipLabel.attributedText = attributed
        tooltipLabel.isHidden = false
        UIView.animate(withDuration: 0.25) { self.tooltipLabel.alpha = 1 }
        tooltipTimer?.invalidate()
        tooltipTimer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: false) { [weak self] _ in
            UIView.animate(withDuration: 0.25) { self?.tooltipLabel.alpha = 0 } completion: { _ in
                self?.tooltipLabel.isHidden = true
                self?.tooltipLabel.attributedText = nil
            }
        }
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
