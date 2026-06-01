import UIKit

struct VerbEntry: Codable {
    let urduInfinitive: String
    let urduMeaning: String
    let label: String
    let urduWord: String
    let urduRoman: String
    let lsdWord: String
    let recordedAt: String
}

final class VerbTrainingViewController: UIViewController {

    private static let groupID  = "group.com.exordiumnetworks.lsdkeyboard"
    private static let fileName = "lsd_verb_training.json"
    private static let accent   = UIColor.systemOrange

    private var remaining: [VerbPrompt] = []
    private var saved: [VerbEntry] = []

    // MARK: - UI

    private let progressLabel = UILabel()
    private let verbBadge     = UILabel()
    private let formLabel     = UILabel()
    private let urduCard      = UIView()
    private let urduWordLabel = UILabel()
    private let romanLabel    = UILabel()
    private let inputField    = UITextField()
    private let bottomBar     = UIView()
    private let skipButton    = UIButton(type: .system)
    private let saveButton    = UIButton(type: .system)
    private var bottomBarBottom: NSLayoutConstraint?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Verb Training"
        view.backgroundColor = .systemGroupedBackground
        loadSaved()
        buildUI()
        showPrompt()
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !remaining.isEmpty { inputField.becomeFirstResponder() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inputField.resignFirstResponder()
    }

    // MARK: - Persistence

    private func loadSaved() {
        if let url = storageURL(),
           let data = try? Data(contentsOf: url),
           let entries = try? JSONDecoder().decode([VerbEntry].self, from: data) {
            saved = entries
        }
        let done = Set(saved.map { "\($0.urduInfinitive)|\($0.label)" })
        remaining = VerbPrompts.all.filter { !done.contains("\($0.urduInfinitive)|\($0.label)") }
    }

    private func persist() {
        guard let url = storageURL(),
              let data = try? JSONEncoder().encode(saved) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func storageURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: Self.groupID)?
            .appendingPathComponent(Self.fileName)
    }

    // MARK: - Build UI

    private func buildUI() {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.layoutMargins = UIEdgeInsets(top: 28, left: 20, bottom: 28, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        progressLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        progressLabel.textColor = .tertiaryLabel
        progressLabel.textAlignment = .center
        stack.addArrangedSubview(progressLabel)

        // Verb badge — English label first keeps LTR paragraph direction.
        verbBadge.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        verbBadge.textColor = Self.accent
        verbBadge.backgroundColor = Self.accent.withAlphaComponent(0.12)
        verbBadge.textAlignment = .center
        verbBadge.layer.cornerRadius = 12
        verbBadge.layer.masksToBounds = true
        let badgeWrap = UIView()
        badgeWrap.translatesAutoresizingMaskIntoConstraints = false
        verbBadge.translatesAutoresizingMaskIntoConstraints = false
        badgeWrap.addSubview(verbBadge)
        NSLayoutConstraint.activate([
            verbBadge.centerXAnchor.constraint(equalTo: badgeWrap.centerXAnchor),
            verbBadge.topAnchor.constraint(equalTo: badgeWrap.topAnchor),
            verbBadge.bottomAnchor.constraint(equalTo: badgeWrap.bottomAnchor),
            verbBadge.widthAnchor.constraint(lessThanOrEqualTo: badgeWrap.widthAnchor),
        ])
        stack.addArrangedSubview(badgeWrap)

        formLabel.font = UIFont.preferredFont(forTextStyle: .title3)
        formLabel.adjustsFontForContentSizeCategory = true
        formLabel.textAlignment = .center
        formLabel.textColor = .secondaryLabel
        stack.addArrangedSubview(formLabel)

        // Urdu reference card
        urduCard.backgroundColor = .secondarySystemGroupedBackground
        urduCard.layer.cornerRadius = 12
        urduCard.translatesAutoresizingMaskIntoConstraints = false

        urduWordLabel.font = UIFont(name: "FatemiMaqala-Regular", size: 42)
            ?? UIFont.systemFont(ofSize: 42)
        urduWordLabel.textAlignment = .center
        urduWordLabel.adjustsFontSizeToFitWidth = true
        urduWordLabel.minimumScaleFactor = 0.6
        urduWordLabel.translatesAutoresizingMaskIntoConstraints = false
        urduCard.addSubview(urduWordLabel)

        romanLabel.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        romanLabel.textColor = .tertiaryLabel
        romanLabel.textAlignment = .center
        romanLabel.translatesAutoresizingMaskIntoConstraints = false
        urduCard.addSubview(romanLabel)

        NSLayoutConstraint.activate([
            urduWordLabel.topAnchor.constraint(equalTo: urduCard.topAnchor, constant: 20),
            urduWordLabel.leadingAnchor.constraint(equalTo: urduCard.leadingAnchor, constant: 16),
            urduWordLabel.trailingAnchor.constraint(equalTo: urduCard.trailingAnchor, constant: -16),
            romanLabel.topAnchor.constraint(equalTo: urduWordLabel.bottomAnchor, constant: 4),
            romanLabel.leadingAnchor.constraint(equalTo: urduCard.leadingAnchor, constant: 16),
            romanLabel.trailingAnchor.constraint(equalTo: urduCard.trailingAnchor, constant: -16),
            romanLabel.bottomAnchor.constraint(equalTo: urduCard.bottomAnchor, constant: -20),
        ])
        stack.addArrangedSubview(urduCard)

        // Input field
        inputField.placeholder = "LSD form…"
        inputField.font = UIFont(name: "FatemiMaqala-Regular", size: 24)
            ?? UIFont.systemFont(ofSize: 24)
        inputField.textAlignment = .right
        inputField.semanticContentAttribute = .forceRightToLeft
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .none
        inputField.spellCheckingType = .no
        inputField.borderStyle = .none
        inputField.backgroundColor = .secondarySystemGroupedBackground
        inputField.layer.cornerRadius = 12
        let lp = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        let rp = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        inputField.leftView = lp;  inputField.leftViewMode  = .always
        inputField.rightView = rp; inputField.rightViewMode = .always
        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done,
                            target: self, action: #selector(dismissKeyboard)),
        ]
        toolbar.sizeToFit()
        inputField.inputAccessoryView = toolbar
        inputField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        inputField.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(inputField)
        inputField.heightAnchor.constraint(equalToConstant: 56).isActive = true

        // Bottom bar
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let sep = UIView()
        sep.backgroundColor = .separator
        sep.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(sep)

        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)

        saveButton.setTitle("Save & Next →", for: .normal)
        saveButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        saveButton.tintColor = Self.accent
        saveButton.isEnabled = false
        saveButton.alpha = 0.4
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [skipButton, saveButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .equalSpacing
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(buttonRow)

        let bbc = bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomBarBottom = bbc

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 56),
            bbc,

            sep.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            sep.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            sep.heightAnchor.constraint(equalToConstant: 0.5),

            buttonRow.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            buttonRow.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            buttonRow.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
        ])
    }

    // MARK: - Show prompt

    private func showPrompt() {
        guard !remaining.isEmpty else { showComplete(); return }

        let prompt = remaining[0]
        let total  = VerbPrompts.all.count
        progressLabel.text = "\(saved.count) of \(total) done  ·  \(remaining.count) remaining"
        // English before Arabic keeps the badge reading left-to-right.
        verbBadge.text  = "  \(prompt.urduMeaning)  —  \(prompt.urduInfinitive)  "
        formLabel.text  = prompt.label.replacingOccurrences(of: "-", with: " ")
        urduWordLabel.text = prompt.urduWord
        romanLabel.text    = prompt.urduRoman
        inputField.text    = ""
        saveButton.isEnabled = false
        saveButton.alpha     = 0.4
    }

    private func showComplete() {
        inputField.resignFirstResponder()
        inputField.isHidden  = true
        skipButton.isHidden  = true
        verbBadge.isHidden   = true
        romanLabel.text      = ""
        urduWordLabel.text   = "✓"

        let total = VerbPrompts.all.count
        progressLabel.text = "All \(total) verb forms recorded"
        formLabel.text     = "Training complete"

        saveButton.isEnabled = true
        saveButton.alpha     = 1
        saveButton.setTitle("Export Training Data", for: .normal)
        saveButton.removeTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        let text = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !remaining.isEmpty else { return }

        let prompt = remaining.removeFirst()
        let entry  = VerbEntry(
            urduInfinitive: prompt.urduInfinitive,
            urduMeaning:    prompt.urduMeaning,
            label:          prompt.label,
            urduWord:       prompt.urduWord,
            urduRoman:      prompt.urduRoman,
            lsdWord:        text,
            recordedAt:     ISO8601DateFormatter().string(from: Date())
        )
        saved.append(entry)
        persist()

        UIView.animate(withDuration: 0.12) { self.inputField.alpha = 0.3 } completion: { _ in
            UIView.animate(withDuration: 0.12) { self.inputField.alpha = 1 }
        }
        showPrompt()
        if !remaining.isEmpty { inputField.becomeFirstResponder() }
    }

    @objc private func skipTapped() {
        guard !remaining.isEmpty else { return }
        remaining.append(remaining.removeFirst())
        showPrompt()
        inputField.becomeFirstResponder()
    }

    @objc private func exportTapped() {
        guard let url = storageURL(),
              FileManager.default.fileExists(atPath: url.path) else { return }
        let stamp = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        let dest  = FileManager.default.temporaryDirectory
            .appendingPathComponent("lsd_verb_training_\(stamp).json")
        try? FileManager.default.removeItem(at: dest)
        guard (try? FileManager.default.copyItem(at: url, to: dest)) != nil else { return }
        let share = UIActivityViewController(activityItems: [dest], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = saveButton
        present(share, animated: true)
    }

    @objc private func textChanged() {
        let hasText = !(inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        saveButton.isEnabled = hasText
        saveButton.alpha     = hasText ? 1 : 0.4
    }

    @objc private func dismissKeyboard() {
        inputField.resignFirstResponder()
    }

    // MARK: - Keyboard avoidance

    @objc private func keyboardWillChange(_ note: Notification) {
        guard
            let frame    = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve    = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        let overlap = max(0, view.bounds.maxY - frame.minY)
        let shift   = max(0, overlap - view.safeAreaInsets.bottom)
        UIView.animate(withDuration: duration, delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.bottomBarBottom?.constant = -shift
            self.view.layoutIfNeeded()
        }
    }
}
