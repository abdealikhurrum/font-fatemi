import UIKit

struct SentenceEntry: Codable {
    let sourceLanguage: String
    let sourceText: String
    let lsdText: String
    let recordedAt: String
}

final class SentenceTrainingViewController: UIViewController, UITextViewDelegate {

    private static let groupID  = "group.com.exordiumnetworks.lsdkeyboard"
    private static let fileName = "lsd_sentence_training.json"

    private let language: String
    private let accent:   UIColor

    private var remaining: [SentencePrompt] = []
    private var saved: [SentenceEntry] = []

    // MARK: - UI

    private let progressLabel  = UILabel()
    private let sourceBadge    = UILabel()
    private let sourceCard     = UIView()
    private let sourceLabel    = UILabel()
    private let inputView_     = UITextView()   // _ suffix avoids clash with UIResponder.inputView
    private let placeholderLabel = UILabel()
    private let bottomBar      = UIView()
    private let skipButton     = UIButton(type: .system)
    private let saveButton     = UIButton(type: .system)
    private var bottomBarBottom: NSLayoutConstraint?

    // MARK: - Init

    init(language: String) {
        self.language = language
        self.accent   = language == "urdu" ? .systemPurple : .systemBlue
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = language == "urdu" ? "Urdu → LSD" : "English → LSD"
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
        if !remaining.isEmpty { inputView_.becomeFirstResponder() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        inputView_.resignFirstResponder()
    }

    // MARK: - Persistence

    private func loadSaved() {
        if let url = storageURL(),
           let data = try? Data(contentsOf: url),
           let entries = try? JSONDecoder().decode([SentenceEntry].self, from: data) {
            saved = entries
        }
        let done = Set(saved.filter { $0.sourceLanguage == language }.map { $0.sourceText })
        let pool = language == "urdu" ? SentencePrompts.urduSentences : SentencePrompts.englishSentences
        remaining = pool.filter { !done.contains($0.sourceText) }
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

        // Language badge
        sourceBadge.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        sourceBadge.textColor = accent
        sourceBadge.backgroundColor = accent.withAlphaComponent(0.12)
        sourceBadge.textAlignment = .center
        sourceBadge.layer.cornerRadius = 10
        sourceBadge.layer.masksToBounds = true
        sourceBadge.text = language == "urdu" ? "  Urdu  " : "  English  "
        let badgeWrap = UIView()
        badgeWrap.translatesAutoresizingMaskIntoConstraints = false
        sourceBadge.translatesAutoresizingMaskIntoConstraints = false
        badgeWrap.addSubview(sourceBadge)
        NSLayoutConstraint.activate([
            sourceBadge.centerXAnchor.constraint(equalTo: badgeWrap.centerXAnchor),
            sourceBadge.topAnchor.constraint(equalTo: badgeWrap.topAnchor),
            sourceBadge.bottomAnchor.constraint(equalTo: badgeWrap.bottomAnchor),
        ])
        stack.addArrangedSubview(badgeWrap)

        // Source sentence card
        sourceCard.backgroundColor = .secondarySystemGroupedBackground
        sourceCard.layer.cornerRadius = 12
        sourceCard.translatesAutoresizingMaskIntoConstraints = false

        let isUrdu = language == "urdu"
        sourceLabel.font = isUrdu
            ? (UIFont(name: "FatemiMaqala-Regular", size: 28) ?? UIFont.systemFont(ofSize: 28))
            : UIFont.preferredFont(forTextStyle: .title3)
        sourceLabel.numberOfLines = 0
        sourceLabel.textAlignment = isUrdu ? .right : .left
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceCard.addSubview(sourceLabel)
        NSLayoutConstraint.activate([
            sourceLabel.topAnchor.constraint(equalTo: sourceCard.topAnchor, constant: 20),
            sourceLabel.leadingAnchor.constraint(equalTo: sourceCard.leadingAnchor, constant: 16),
            sourceLabel.trailingAnchor.constraint(equalTo: sourceCard.trailingAnchor, constant: -16),
            sourceLabel.bottomAnchor.constraint(equalTo: sourceCard.bottomAnchor, constant: -20),
        ])
        stack.addArrangedSubview(sourceCard)

        // Input text view (for the LSD translation)
        let inputCard = UIView()
        inputCard.backgroundColor = .secondarySystemGroupedBackground
        inputCard.layer.cornerRadius = 12
        inputCard.translatesAutoresizingMaskIntoConstraints = false

        inputView_.delegate = self
        inputView_.font = UIFont(name: "FatemiMaqala-Regular", size: 22)
            ?? UIFont.systemFont(ofSize: 22)
        inputView_.textAlignment = .right
        inputView_.semanticContentAttribute = .forceRightToLeft
        inputView_.autocorrectionType = .no
        inputView_.autocapitalizationType = .none
        inputView_.spellCheckingType = .no
        inputView_.isScrollEnabled = false
        inputView_.backgroundColor = .clear
        inputView_.textContainerInset = UIEdgeInsets(top: 14, left: 10, bottom: 14, right: 10)
        inputView_.translatesAutoresizingMaskIntoConstraints = false

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done,
                            target: self, action: #selector(dismissKeyboard)),
        ]
        toolbar.sizeToFit()
        inputView_.inputAccessoryView = toolbar

        // Placeholder label overlaid on the text view
        placeholderLabel.text = "Type LSD translation…"
        placeholderLabel.font = UIFont.systemFont(ofSize: 16)
        placeholderLabel.textColor = .placeholderText
        placeholderLabel.textAlignment = .right
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false

        inputCard.addSubview(inputView_)
        inputCard.addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            inputView_.topAnchor.constraint(equalTo: inputCard.topAnchor),
            inputView_.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor),
            inputView_.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor),
            inputView_.bottomAnchor.constraint(equalTo: inputCard.bottomAnchor),
            inputView_.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),

            placeholderLabel.topAnchor.constraint(equalTo: inputCard.topAnchor, constant: 14),
            placeholderLabel.trailingAnchor.constraint(equalTo: inputCard.trailingAnchor, constant: -16),
            placeholderLabel.leadingAnchor.constraint(equalTo: inputCard.leadingAnchor, constant: 16),
        ])
        stack.addArrangedSubview(inputCard)

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
        saveButton.tintColor = accent
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

        let pool = language == "urdu" ? SentencePrompts.urduSentences.count
                                      : SentencePrompts.englishSentences.count
        let done = saved.filter { $0.sourceLanguage == language }.count
        progressLabel.text = "\(done) of \(pool) done  ·  \(remaining.count) remaining"
        sourceLabel.text = remaining[0].sourceText
        inputView_.text = ""
        placeholderLabel.isHidden = false
        saveButton.isEnabled = false
        saveButton.alpha = 0.4
    }

    private func showComplete() {
        inputView_.resignFirstResponder()
        inputView_.isHidden = true
        skipButton.isHidden = true
        placeholderLabel.isHidden = true

        let pool = language == "urdu" ? SentencePrompts.urduSentences.count
                                      : SentencePrompts.englishSentences.count
        progressLabel.text = "All \(pool) sentences recorded"
        sourceLabel.text   = "✓"
        sourceLabel.textAlignment = .center

        saveButton.isEnabled = true
        saveButton.alpha     = 1
        saveButton.setTitle("Export Training Data", for: .normal)
        saveButton.removeTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func saveTapped() {
        let text = inputView_.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !remaining.isEmpty else { return }

        let prompt = remaining.removeFirst()
        let entry  = SentenceEntry(
            sourceLanguage: prompt.sourceLanguage,
            sourceText:     prompt.sourceText,
            lsdText:        text,
            recordedAt:     ISO8601DateFormatter().string(from: Date())
        )
        saved.append(entry)
        persist()

        UIView.animate(withDuration: 0.12) { self.inputView_.alpha = 0.3 } completion: { _ in
            UIView.animate(withDuration: 0.12) { self.inputView_.alpha = 1 }
        }
        showPrompt()
        if !remaining.isEmpty { inputView_.becomeFirstResponder() }
    }

    @objc private func skipTapped() {
        guard !remaining.isEmpty else { return }
        remaining.append(remaining.removeFirst())
        showPrompt()
        inputView_.becomeFirstResponder()
    }

    @objc private func exportTapped() {
        guard let url = storageURL(),
              FileManager.default.fileExists(atPath: url.path) else { return }
        let stamp = String(ISO8601DateFormatter().string(from: Date()).prefix(10))
        let dest  = FileManager.default.temporaryDirectory
            .appendingPathComponent("lsd_sentence_training_\(stamp).json")
        try? FileManager.default.removeItem(at: dest)
        guard (try? FileManager.default.copyItem(at: url, to: dest)) != nil else { return }
        let share = UIActivityViewController(activityItems: [dest], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = saveButton
        present(share, animated: true)
    }

    @objc private func dismissKeyboard() {
        inputView_.resignFirstResponder()
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        let hasText = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        placeholderLabel.isHidden = hasText
        saveButton.isEnabled = hasText
        saveButton.alpha     = hasText ? 1 : 0.4
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
