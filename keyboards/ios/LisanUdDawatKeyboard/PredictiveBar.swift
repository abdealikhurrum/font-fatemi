import UIKit

// The three-suggestion strip above the keyboard.
// Without this the keyboard feels unfinished — even placeholder text helps.
// Feed real predictions from the transliteration model here later.

protocol PredictiveBarDelegate: AnyObject {
    func predictiveBar(_ bar: PredictiveBar, didSelect suggestion: String)
}

final class PredictiveBar: UIView {

    weak var delegate: PredictiveBarDelegate?

    static let height: CGFloat = 44

    private var buttons: [UIButton] = []
    private let separatorColor = KeyboardColors.separator

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = KeyboardColors.predictiveBar
        buildButtons()
        addSeparators()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public

    // Supply up to 3 suggestions; pass fewer or empty to clear.
    func update(suggestions: [String]) {
        for (i, btn) in buttons.enumerated() {
            let text = i < suggestions.count ? suggestions[i] : ""
            btn.setTitle(text, for: .normal)
            btn.isEnabled = !text.isEmpty
            btn.alpha = text.isEmpty ? 0.35 : 1
        }
    }

    // MARK: - Build

    private func buildButtons() {
        for i in 0..<3 {
            let btn = UIButton(type: .system)
            btn.setTitleColor(.label, for: .normal)
            btn.setTitleColor(.secondaryLabel, for: .disabled)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
            btn.titleLabel?.lineBreakMode = .byTruncatingTail
            btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            // Middle suggestion is slightly bolder — it's the primary pick
            if i == 1 { btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium) }
            btn.tag = i
            btn.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            // Touch-down highlight
            btn.addTarget(self, action: #selector(highlightBtn(_:)), for: .touchDown)
            btn.addTarget(self, action: #selector(unhighlightBtn(_:)),
                          for: [.touchUpInside, .touchUpOutside, .touchCancel])
            addSubview(btn)
            buttons.append(btn)
        }
        update(suggestions: [])
    }

    private func addSeparators() {
        for _ in 0..<2 {
            let s = UIView()
            s.backgroundColor = separatorColor
            addSubview(s)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let w = bounds.width / 3
        let h = bounds.height
        for (i, btn) in buttons.enumerated() {
            btn.frame = CGRect(x: CGFloat(i) * w, y: 0, width: w, height: h)
        }
        let seps = subviews.filter { !($0 is UIButton) }
        for (i, sep) in seps.enumerated() {
            sep.frame = CGRect(x: CGFloat(i + 1) * w - 0.5, y: 8, width: 1, height: h - 16)
        }
    }

    // MARK: - Actions

    @objc private func suggestionTapped(_ btn: UIButton) {
        guard let text = btn.title(for: .normal), !text.isEmpty else { return }
        delegate?.predictiveBar(self, didSelect: text)
    }

    @objc private func highlightBtn(_ btn: UIButton) {
        UIView.animate(withDuration: 0.05) {
            btn.backgroundColor = UIColor(white: 0.78, alpha: 1)
        }
    }

    @objc private func unhighlightBtn(_ btn: UIButton) {
        UIView.animate(withDuration: 0.1) {
            btn.backgroundColor = .clear
        }
    }
}
