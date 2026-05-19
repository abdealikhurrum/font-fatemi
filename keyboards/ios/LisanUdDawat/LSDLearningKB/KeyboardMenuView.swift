import UIKit

// Full-screen settings panel that slides up over the keyboard area.
// Triggered from the ⚙ button in the predictive bar.

final class KeyboardMenuView: UIView {

    var onDismiss: (() -> Void)?

    private weak var customDelayRow: UIView?
    private weak var customValueLabel: UILabel?

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
        addDelaySection(to: stack)
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

    private func addDelaySection(to stack: UIStackView) {
        // Thin separator between double-tap toggle and its delay sub-row
        let subSep = UIView()
        subSep.backgroundColor = KeyboardColors.separator.withAlphaComponent(0.4)
        subSep.translatesAutoresizingMaskIntoConstraints = false
        subSep.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        stack.addArrangedSubview(subSep)

        // Row: label + segmented control
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = "Tap delay"
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let seg = UISegmentedControl(items: ["0.25s", "0.35s", "0.50s", "Custom"])
        seg.translatesAutoresizingMaskIntoConstraints = false
        seg.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12)], for: .normal)
        switch KeyboardSettings.doubleTapDelayPreset {
        case .short:  seg.selectedSegmentIndex = 0
        case .normal: seg.selectedSegmentIndex = 1
        case .long:   seg.selectedSegmentIndex = 2
        case .custom: seg.selectedSegmentIndex = 3
        }

        row.addSubview(lbl)
        row.addSubview(seg)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 44),
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            seg.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            seg.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            lbl.trailingAnchor.constraint(lessThanOrEqualTo: seg.leadingAnchor, constant: -8),
        ])
        stack.addArrangedSubview(row)

        // Custom value row (hidden unless "Custom" is selected)
        let customRow = buildCustomDelayRow()
        customRow.isHidden = KeyboardSettings.doubleTapDelayPreset != .custom
        stack.addArrangedSubview(customRow)
        customDelayRow = customRow

        seg.addAction(UIAction { [weak self] _ in
            let customRow = self?.customDelayRow
            switch seg.selectedSegmentIndex {
            case 0:
                KeyboardSettings.doubleTapDelayPreset = .short
                KeyboardSettings.doubleTapDelay = 0.25
                customRow?.isHidden = true
            case 1:
                KeyboardSettings.doubleTapDelayPreset = .normal
                KeyboardSettings.doubleTapDelay = 0.35
                customRow?.isHidden = true
            case 2:
                KeyboardSettings.doubleTapDelayPreset = .long
                KeyboardSettings.doubleTapDelay = 0.50
                customRow?.isHidden = true
            case 3:
                KeyboardSettings.doubleTapDelayPreset = .custom
                customRow?.isHidden = false
            default: break
            }
        }, for: .valueChanged)
    }

    private func buildCustomDelayRow() -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let lbl = UILabel()
        lbl.text = "Custom value"
        lbl.font = .systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false

        let valueLbl = UILabel()
        valueLbl.text = String(format: "%.2fs", KeyboardSettings.doubleTapDelay)
        valueLbl.font = .monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        valueLbl.textColor = .label
        valueLbl.textAlignment = .right
        valueLbl.translatesAutoresizingMaskIntoConstraints = false
        valueLbl.setContentHuggingPriority(.required, for: .horizontal)
        customValueLabel = valueLbl

        let stepper = UIStepper()
        stepper.minimumValue = 0.10
        stepper.maximumValue = 1.50
        stepper.stepValue    = 0.05
        stepper.value        = KeyboardSettings.doubleTapDelay
        stepper.translatesAutoresizingMaskIntoConstraints = false
        stepper.addAction(UIAction { [weak self] _ in
            KeyboardSettings.doubleTapDelay = stepper.value
            self?.customValueLabel?.text = String(format: "%.2fs", stepper.value)
        }, for: .valueChanged)

        row.addSubview(lbl)
        row.addSubview(valueLbl)
        row.addSubview(stepper)
        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 44),
            lbl.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            lbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            stepper.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            stepper.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            valueLbl.trailingAnchor.constraint(equalTo: stepper.leadingAnchor, constant: -8),
            valueLbl.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        return row
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
