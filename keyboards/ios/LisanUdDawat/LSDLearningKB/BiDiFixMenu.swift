import UIKit

// Slide-up panel offering BiDi fix options.
// Shown when the user taps the animated BiDi fix button in the predictive bar.

final class BiDiFixMenu: UIView {

    var onFixApplied: ((BiDiFix) -> Void)?
    var onDismiss:    (() -> Void)?

    enum BiDiFix { case smart, fixLine, fixAtCursor, markSelectionLTR }

    private let issue: BiDiAnalyzer.Issue

    init(issue: BiDiAnalyzer.Issue) {
        self.issue = issue
        super.init(frame: .zero)
        buildUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Show

    static func show(in parent: UIView, issue: BiDiAnalyzer.Issue) -> BiDiFixMenu {
        let menu = BiDiFixMenu(issue: issue)
        menu.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(menu)
        NSLayoutConstraint.activate([
            menu.topAnchor.constraint(equalTo: parent.topAnchor),
            menu.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
            menu.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
            menu.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
        ])
        parent.layoutIfNeeded()
        menu.transform = CGAffineTransform(translationX: 0, y: parent.bounds.height)
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) {
            menu.transform = .identity
        }
        return menu
    }

    func dismiss() {
        UIView.animate(withDuration: 0.18, delay: 0, options: .curveEaseIn) {
            self.transform = CGAffineTransform(translationX: 0, y: self.bounds.height)
        } completion: { _ in
            self.removeFromSuperview()
            self.onDismiss?()
        }
    }

    // MARK: - Build

    private func buildUI() {
        // Tapping the backdrop dismisses
        isUserInteractionEnabled = true
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(backdropTapped)))
        backgroundColor = .clear

        let panel = UIView()
        panel.backgroundColor = KeyboardColors.background
        panel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(panel)
        NSLayoutConstraint.activate([
            panel.leadingAnchor.constraint(equalTo: leadingAnchor),
            panel.trailingAnchor.constraint(equalTo: trailingAnchor),
            panel.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        // Absorb taps so they don't pass through to the backdrop
        panel.addGestureRecognizer(UITapGestureRecognizer(target: nil, action: nil))

        let header = buildHeader()
        panel.addSubview(header)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: panel.topAnchor),
            header.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 44),
        ])

        let sep = hairline()
        panel.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.topAnchor.constraint(equalTo: header.bottomAnchor),
            sep.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: sep.bottomAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -16),
        ])

        // Primary "Fix" button
        let fixBtn = UIButton(type: .system)
        fixBtn.setTitle("Fix", for: .normal)
        fixBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        fixBtn.backgroundColor = UIColor(red: 0, green: 0.478, blue: 1, alpha: 1)
        fixBtn.setTitleColor(.white, for: .normal)
        fixBtn.layer.cornerRadius = 10
        fixBtn.translatesAutoresizingMaskIntoConstraints = false
        fixBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        fixBtn.addTarget(self, action: #selector(fixTapped), for: .touchUpInside)
        stack.addArrangedSubview(fixBtn)

        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 10).isActive = true
        stack.addArrangedSubview(spacer)

        stack.addArrangedSubview(hairline())
        addRow(to: stack,
               title: "Fix this line",
               subtitle: "Adds a direction mark at the start of this line",
               action: { [weak self] in self?.applyFix(.fixLine) })
        stack.addArrangedSubview(hairline())
        addRow(to: stack,
               title: "Fix at cursor",
               subtitle: "Adds a direction mark at the cursor position",
               action: { [weak self] in self?.applyFix(.fixAtCursor) })
        stack.addArrangedSubview(hairline())
        addRow(to: stack,
               title: "Mark selection as left-to-right",
               subtitle: "Wraps the selected text so it reads left-to-right",
               action: { [weak self] in self?.applyFix(.markSelectionLTR) })
    }

    private func buildHeader() -> UIView {
        let header = UIView()
        header.backgroundColor = KeyboardColors.predictiveBar
        header.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "Fix Text Direction"
        title.font = .systemFont(ofSize: 14, weight: .semibold)
        title.textColor = .label
        title.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(title)

        let done = UIButton(type: .system)
        done.setTitle("Done", for: .normal)
        done.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        done.translatesAutoresizingMaskIntoConstraints = false
        done.addTarget(self, action: #selector(backdropTapped), for: .touchUpInside)
        header.addSubview(done)

        NSLayoutConstraint.activate([
            title.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: header.centerYAnchor),
            done.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -14),
            done.centerYAnchor.constraint(equalTo: header.centerYAnchor),
        ])
        return header
    }

    private func addRow(to stack: UIStackView, title: String, subtitle: String, action: @escaping () -> Void) {
        let row = UIControl()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 52).isActive = true
        row.addAction(UIAction { _ in action() }, for: .touchUpInside)

        let vstack = UIStackView()
        vstack.axis = .vertical
        vstack.spacing = 2
        vstack.isUserInteractionEnabled = false
        vstack.translatesAutoresizingMaskIntoConstraints = false

        let titleLbl = UILabel()
        titleLbl.text = title
        titleLbl.font = .systemFont(ofSize: 14)
        titleLbl.textColor = .label

        let subLbl = UILabel()
        subLbl.text = subtitle
        subLbl.font = .systemFont(ofSize: 11)
        subLbl.textColor = .secondaryLabel
        subLbl.numberOfLines = 2

        vstack.addArrangedSubview(titleLbl)
        vstack.addArrangedSubview(subLbl)
        row.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            vstack.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            vstack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
        ])
        stack.addArrangedSubview(row)
    }

    private func hairline() -> UIView {
        let v = UIView()
        v.backgroundColor = KeyboardColors.separator
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }

    // MARK: - Actions

    @objc private func fixTapped()      { applyFix(.smart) }
    @objc private func backdropTapped() { dismiss() }

    private func applyFix(_ fix: BiDiFix) {
        onFixApplied?(fix)
        dismiss()
    }
}
