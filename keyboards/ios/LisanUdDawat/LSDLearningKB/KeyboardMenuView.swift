import UIKit

// Full-screen settings panel that slides up over the keyboard area.
// Triggered from the ⚙ button in the predictive bar.

final class KeyboardMenuView: UIView {

    var onDismiss: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = KeyboardColors.background

        // Header
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = KeyboardColors.predictiveBar
        addSubview(header)

        let titleLabel = UILabel()
        titleLabel.text = "Keyboard Settings"
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(titleLabel)

        let doneBtn = UIButton(type: .system)
        doneBtn.setTitle("Done", for: .normal)
        doneBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        doneBtn.translatesAutoresizingMaskIntoConstraints = false
        doneBtn.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        header.addSubview(doneBtn)

        // Separator under header
        let headerSep = UIView()
        headerSep.backgroundColor = KeyboardColors.separator
        headerSep.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headerSep)

        // Settings rows
        let stack = UIStackView()
        stack.axis    = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        addToggle(to: stack,
            label: "Word predictions",
            getValue: { KeyboardSettings.predictionEnabled },
            setValue: { KeyboardSettings.predictionEnabled = $0 }
        )
        addSeparator(to: stack)
        addToggle(to: stack,
            label: "Corpus logging",
            getValue: { KeyboardSettings.corpusEnabled },
            setValue: { KeyboardSettings.corpusEnabled = $0 }
        )
        addSeparator(to: stack)
        addToggle(to: stack,
            label: "Double-tap secondary char",
            getValue: { KeyboardSettings.doubleTapEnabled },
            setValue: { KeyboardSettings.doubleTapEnabled = $0 }
        )
        addSeparator(to: stack)
        addActionRow(to: stack,
            label: "Copy corpus to clipboard  (\(CorpusLogger.shared.wordCount) words)",
            action: { [weak self] in
                let text = CorpusLogger.shared.exportText()
                UIPasteboard.general.string = text.isEmpty ? "" : text
                print("[CorpusLogger] copied \(CorpusLogger.shared.wordCount) words to clipboard")
                self?.dismissTapped()
            }
        )

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: topAnchor),
            header.leadingAnchor.constraint(equalTo: leadingAnchor),
            header.trailingAnchor.constraint(equalTo: trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: PredictiveBar.height),

            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            doneBtn.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -12),
            doneBtn.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            headerSep.topAnchor.constraint(equalTo: header.bottomAnchor),
            headerSep.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerSep.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerSep.heightAnchor.constraint(equalToConstant: 0.5),

            stack.topAnchor.constraint(equalTo: headerSep.bottomAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }

    // MARK: - Row builders

    private func addToggle(
        to stack: UIStackView,
        label: String,
        getValue: @escaping () -> Bool,
        setValue: @escaping (Bool) -> Void
    ) {
        let row    = UIView()
        let lbl    = UILabel()
        let toggle = UISwitch()

        lbl.text      = label
        lbl.font      = .systemFont(ofSize: 15)
        lbl.textColor = .label
        lbl.translatesAutoresizingMaskIntoConstraints = false

        toggle.isOn   = getValue()
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addAction(UIAction { _ in setValue(toggle.isOn) }, for: .valueChanged)

        row.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(lbl)
        row.addSubview(toggle)

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
        sep.backgroundColor = KeyboardColors.separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        sep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(sep)
    }

    private func addActionRow(to stack: UIStackView, label: String, action: @escaping () -> Void) {
        let btn = UIButton(type: .system)
        btn.setTitle(label, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        btn.contentHorizontalAlignment = .leading
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addAction(UIAction { _ in action() }, for: .touchUpInside)

        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(btn)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 44),
            btn.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            btn.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            btn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        stack.addArrangedSubview(row)
    }

    // MARK: - Show / Dismiss

    static func show(in parent: UIView) -> KeyboardMenuView {
        let screen = KeyboardMenuView()
        screen.translatesAutoresizingMaskIntoConstraints = false
        screen.transform = CGAffineTransform(translationX: 0, y: parent.bounds.height)
        parent.addSubview(screen)
        NSLayoutConstraint.activate([
            screen.topAnchor.constraint(equalTo: parent.topAnchor),
            screen.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            screen.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            screen.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        ])
        parent.layoutIfNeeded()
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            screen.transform = .identity
        }
        return screen
    }

    @objc func dismissTapped() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
        } completion: { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        }
    }
}
