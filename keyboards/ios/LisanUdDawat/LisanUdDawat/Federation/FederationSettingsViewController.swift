import UIKit
import Combine

// Full-screen settings panel for the federation feature.
// Shows pair stats, privacy explanation, manual push/pull buttons,
// and the auto-push toggle with scheduling details.

final class FederationSettingsViewController: UIViewController {

    private let manager = FederationManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Views

    private lazy var scrollView   = UIScrollView()
    private lazy var stackView    = UIStackView()
    private lazy var statusLabel  = UILabel()
    private lazy var pushButton   = UIButton(type: .system)
    private lazy var pullButton   = UIButton(type: .system)
    private lazy var autoToggle        = UISwitch()
    private lazy var predictionToggle  = UISwitch()
    private lazy var activityIndicator = UIActivityIndicatorView(style: .medium)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Keyboard Contribution"
        view.backgroundColor = .systemGroupedBackground
        buildUI()
        bindManager()
        refreshStats()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager.reload()
    }

    // MARK: - UI Construction

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        stackView.addArrangedSubview(corpusCard())
        stackView.addArrangedSubview(keyboardCard())
        stackView.addArrangedSubview(privacyCard())
        stackView.addArrangedSubview(statsCard())
        stackView.addArrangedSubview(manualCard())
        stackView.addArrangedSubview(autoCard())
        stackView.addArrangedSubview(modelCard())
    }

    // MARK: - Cards

    private func corpusCard() -> UIView {
        let v = cardContainer(title: "Corpus")

        let notepadText = UserDefaults.standard.string(forKey: "notepad_text") ?? ""
        let wordCount = notepadText
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count

        v.addArrangedSubview(label(
            "Notepad corpus: \(wordCount) words",
            size: 15, weight: .medium
        ))
        v.addArrangedSubview(label(
            "Everything you type in the Notepad tab is saved here and can be exported " +
            "as a plain-text training file.",
            size: 14, color: .secondaryLabel
        ))

        let exportBtn = UIButton(type: .system)
        exportBtn.setTitle("Export notepad as corpus", for: .normal)
        exportBtn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        exportBtn.backgroundColor = .systemIndigo
        exportBtn.setTitleColor(.white, for: .normal)
        exportBtn.layer.cornerRadius = 10
        exportBtn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        exportBtn.isEnabled = wordCount > 0
        exportBtn.alpha = wordCount > 0 ? 1.0 : 0.4
        exportBtn.addTarget(self, action: #selector(exportNotepadCorpus), for: .touchUpInside)
        v.addArrangedSubview(exportBtn)

        v.addArrangedSubview(label(
            "Keyboard typing data (from all apps) is collected in the keyboard extension " +
            "and requires an App Group to appear here. Enable the " +
            "\"group.com.exordiumnetworks.lsdkeyboard\" capability in both targets via " +
            "Xcode → Signing & Capabilities to unlock cross-process corpus access.",
            size: 13, color: .tertiaryLabel
        ))

        return v
    }

    @objc private func exportNotepadCorpus() {
        let text = UserDefaults.standard.string(forKey: "notepad_text") ?? ""
        guard !text.isEmpty else { return }
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("lsd_corpus.txt")
        try? text.write(to: tmpURL, atomically: true, encoding: .utf8)
        let share = UIActivityViewController(activityItems: [tmpURL], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = view
        present(share, animated: true)
    }

    private func keyboardCard() -> UIView {
        let v = cardContainer(title: "Keyboard")

        let body = label(
            "Word predictions appear above the keyboard. " +
            "Turn this on once the transliteration model is connected.",
            size: 14, color: .secondaryLabel
        )
        v.addArrangedSubview(body)

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        row.addArrangedSubview(label("Show predictions", size: 16))
        predictionToggle.isOn = KeyboardSettings.predictionEnabled
        predictionToggle.addTarget(self, action: #selector(predictionToggleChanged), for: .valueChanged)
        row.addArrangedSubview(predictionToggle)
        v.addArrangedSubview(row)

        return v
    }

    private func privacyCard() -> UIView {
        card(title: "How this works", body: """
        When you type in Lisan ud Dawat and accept or correct a transliteration, \
        the keyboard saves that pair privately on your device.

        When you contribute, the app trains a local copy of the model on your pairs \
        and uploads only the resulting weight file — a mathematical summary that \
        contains no recoverable text. Your original input is never transmitted.

        Weight files from many contributors are averaged together to improve the \
        shared model, which is then made available to everyone.
        """)
    }

    private func statsCard() -> UIView {
        let v = cardContainer(title: "Your contribution")
        statusLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel
        v.addArrangedSubview(statusLabel)
        return v
    }

    private func manualCard() -> UIView {
        let v = cardContainer(title: "Contribute now")

        let body = label(
            "Train locally and upload your weight contribution immediately. " +
            "Requires Wi-Fi or cellular, and takes 1–5 minutes.",
            size: 14, color: .secondaryLabel
        )
        v.addArrangedSubview(body)

        pushButton.setTitle("Contribute weights", for: .normal)
        pushButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        pushButton.backgroundColor = UIColor.systemBlue
        pushButton.setTitleColor(.white, for: .normal)
        pushButton.layer.cornerRadius = 10
        pushButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        pushButton.addTarget(self, action: #selector(manualPush), for: .touchUpInside)
        v.addArrangedSubview(pushButton)

        activityIndicator.hidesWhenStopped = true
        v.addArrangedSubview(activityIndicator)

        return v
    }

    private func autoCard() -> UIView {
        let v = cardContainer(title: "Automatic contribution")

        let body = label(
            "When enabled, the keyboard contributes automatically while your device " +
            "is charging overnight — only when you have at least " +
            "\(manager.config.autoPushThreshold) new pairs.",
            size: 14, color: .secondaryLabel
        )
        v.addArrangedSubview(body)

        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .equalSpacing
        row.alignment = .center
        let lbl = label("Auto-contribute", size: 16)
        autoToggle.isOn = manager.autoPushEnabled
        autoToggle.addTarget(self, action: #selector(toggleAutoChanged), for: .valueChanged)
        row.addArrangedSubview(lbl)
        row.addArrangedSubview(autoToggle)
        v.addArrangedSubview(row)

        return v
    }

    private func modelCard() -> UIView {
        let v = cardContainer(title: "Model updates")

        let body = label(
            "Pull the latest community-merged model at any time. " +
            "Updates happen automatically in the background every 6 hours.",
            size: 14, color: .secondaryLabel
        )
        v.addArrangedSubview(body)

        pullButton.setTitle("Check for update", for: .normal)
        pullButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        pullButton.backgroundColor = UIColor.systemGreen
        pullButton.setTitleColor(.white, for: .normal)
        pullButton.layer.cornerRadius = 10
        pullButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        pullButton.addTarget(self, action: #selector(manualPull), for: .touchUpInside)
        v.addArrangedSubview(pullButton)

        return v
    }

    // MARK: - Actions

    @objc private func manualPush() {
        Task { await manager.pushNow() }
    }

    @objc private func manualPull() {
        Task { await manager.pullLatest() }
    }

    @objc private func toggleAutoChanged() {
        manager.autoPushEnabled = autoToggle.isOn
    }

    @objc private func predictionToggleChanged() {
        KeyboardSettings.predictionEnabled = predictionToggle.isOn
    }

    // MARK: - Bindings

    private func bindManager() {
        manager.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in self?.applyStatus(status) }
            .store(in: &cancellables)

        manager.$pendingPairCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshStats() }
            .store(in: &cancellables)

        Publishers.CombineLatest(manager.$localModelVersion, manager.$remoteModelVersion)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in self?.refreshStats() }
            .store(in: &cancellables)
    }

    private func refreshStats() {
        let pending = manager.pendingPairCount
        let total   = PairCollector.shared.totalCount()
        let push    = manager.lastPushDate.map { format($0) } ?? "Never"
        let pull    = manager.lastPullDate.map { format($0) } ?? "Never"
        statusLabel.text = """
        Pending pairs:    \(pending)
        Total collected:  \(total)
        Last contributed: \(push)
        Last model pull:  \(pull)
        Local version:    \(manager.localModelVersion)
        Remote version:   \(manager.remoteModelVersion)
        """

        let hasEnough = pending >= manager.config.autoPushThreshold
        pushButton.alpha = pending > 0 ? 1.0 : 0.5
        pushButton.isEnabled = pending > 0
        if !hasEnough && autoToggle.isOn {
            let needed = manager.config.autoPushThreshold - pending
            pushButton.setTitle(
                "Contribute weights (\(needed) more pairs for auto-trigger)",
                for: .normal
            )
        } else {
            pushButton.setTitle("Contribute weights", for: .normal)
        }
    }

    private func applyStatus(_ status: FederationManager.Status) {
        let busy = status == .training || status == .uploading || status == .downloading
        pushButton.isEnabled = !busy
        pullButton.isEnabled = !busy
        busy ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()

        if case .error(let msg) = status {
            let alert = UIAlertController(
                title: "Error", message: msg, preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }

        let statusText: String
        switch status {
        case .idle:        statusText = "Idle"
        case .training:    statusText = "Training locally…"
        case .uploading:   statusText = "Uploading weight delta…"
        case .downloading: statusText = "Downloading model…"
        case .error:       statusText = "Error (see above)"
        }
        pushButton.setTitle(statusText, for: .disabled)
    }

    // MARK: - Helpers

    private func cardContainer(title: String) -> UIStackView {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 10
        v.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        v.isLayoutMarginsRelativeArrangement = true
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        let t = label(title, size: 17, weight: .semibold)
        v.addArrangedSubview(t)
        return v
    }

    private func card(title: String, body: String) -> UIView {
        let v = cardContainer(title: title)
        v.addArrangedSubview(label(body, size: 14, color: .secondaryLabel))
        return v
    }

    private func label(
        _ text: String,
        size: CGFloat = 15,
        weight: UIFont.Weight = .regular,
        color: UIColor = .label
    ) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: size, weight: weight)
        l.textColor = color
        l.numberOfLines = 0
        return l
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}
