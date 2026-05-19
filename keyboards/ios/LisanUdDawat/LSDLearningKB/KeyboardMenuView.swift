import UIKit

protocol KeyboardMenuDelegate: AnyObject {
    func keyboardMenuDidDismiss()
}

final class KeyboardMenuView: UIView {

    weak var delegate: KeyboardMenuDelegate?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 14
        layer.shadowColor  = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius  = 12
        layer.shadowOffset  = CGSize(width: 0, height: -2)
        clipsToBounds = false

        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])

        let title = UILabel()
        title.text      = "Keyboard Settings"
        title.font      = .systemFont(ofSize: 12, weight: .semibold)
        title.textColor = .tertiaryLabel
        title.textAlignment = .center
        stack.addArrangedSubview(title)
        stack.setCustomSpacing(8, after: title)

        addToggleRow(to: stack,
            label: "Word predictions",
            getValue: { KeyboardSettings.predictionEnabled },
            setValue: { KeyboardSettings.predictionEnabled = $0 }
        )
        addSeparator(to: stack)
        addToggleRow(to: stack,
            label: "Corpus logging",
            getValue: { KeyboardSettings.corpusEnabled },
            setValue: { KeyboardSettings.corpusEnabled = $0 }
        )
        addSeparator(to: stack)
        addToggleRow(to: stack,
            label: "Double-tap secondary char",
            getValue: { KeyboardSettings.doubleTapEnabled },
            setValue: { KeyboardSettings.doubleTapEnabled = $0 }
        )
        addSeparator(to: stack)

        // Copy corpus button
        let copyBtn = UIButton(type: .system)
        copyBtn.setTitle("Copy corpus to clipboard", for: .normal)
        copyBtn.titleLabel?.font = .systemFont(ofSize: 15)
        copyBtn.contentHorizontalAlignment = .leading
        copyBtn.addTarget(self, action: #selector(copyCorpus), for: .touchUpInside)
        let copyRow = rowWrap(copyBtn, height: 44)
        stack.addArrangedSubview(copyRow)
    }

    // MARK: - Row builders

    private func addToggleRow(
        to stack: UIStackView,
        label: String,
        getValue: @escaping () -> Bool,
        setValue: @escaping (Bool) -> Void
    ) {
        let row   = UIView()
        let lbl   = UILabel()
        let toggle = UISwitch()

        lbl.text      = label
        lbl.font      = .systemFont(ofSize: 15)
        lbl.textColor = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false

        toggle.isOn   = getValue()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addAction(UIAction { _ in setValue(toggle.isOn) }, for: .valueChanged)

        row.addSubview(lbl)
        row.addSubview(toggle)
        row.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 44),
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            lbl.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -8),
        ])
        stack.addArrangedSubview(row)
    }

    private func addSeparator(to stack: UIStackView) {
        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(sep)
    }

    private func rowWrap(_ view: UIView, height: CGFloat) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(view)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: height),
            view.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            view.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        return row
    }

    // MARK: - Actions

    @objc private func copyCorpus() {
        let text = CorpusLogger.shared.exportText()
        UIPasteboard.general.string = text.isEmpty ? "" : text
        print("[CorpusLogger] copied \(CorpusLogger.shared.wordCount) words to clipboard")
        dismiss()
    }

    func dismiss() {
        UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(translationX: 0, y: 8)
        } completion: { _ in
            self.removeFromSuperview()
            self.delegate?.keyboardMenuDidDismiss()
        }
    }

    // MARK: - Show

    static func show(in parent: UIView, above anchorY: CGFloat) -> KeyboardMenuView {
        let menu = KeyboardMenuView()
        menu.alpha     = 0
        menu.transform = CGAffineTransform(translationX: 0, y: 8)
        menu.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(menu)

        let margin: CGFloat = 12
        NSLayoutConstraint.activate([
            menu.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: margin),
            menu.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -margin),
            menu.bottomAnchor.constraint(equalTo: parent.topAnchor, constant: anchorY - 4),
        ])
        parent.layoutIfNeeded()

        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) {
            menu.alpha     = 1
            menu.transform = .identity
        }
        return menu
    }
}
