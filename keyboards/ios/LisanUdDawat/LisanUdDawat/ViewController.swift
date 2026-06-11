import UIKit

final class ViewController: UIViewController {

    private lazy var scrollView    = UIScrollView()
    private lazy var stackView     = UIStackView()
    private lazy var installButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Setup"
        view.backgroundColor = .systemGroupedBackground
        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showFirstRunIfNeeded()
    }

    private func showFirstRunIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "first_run_complete") else { return }
        UserDefaults.standard.set(true, forKey: "first_run_complete")
        let vc = LessonViewController(module: LessonCatalog.quickStart)
        vc.onFinish = { [weak self] in self?.dismiss(animated: true) }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    // MARK: - Layout

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

        stackView.addArrangedSubview(keyboardCard())
        stackView.addArrangedSubview(appearanceCard())
        stackView.addArrangedSubview(fontCard())
        stackView.addArrangedSubview(corpusCard())
        stackView.addArrangedSubview(aboutCard())
    }

    // MARK: - Cards

    private func keyboardCard() -> UIView {
        let v = cardContainer(title: "Enable Keyboard")
        v.addArrangedSubview(bodyLabel(
            "Settings → General → Keyboard → Keyboards → " +
            "Add New Keyboard… → LigaCheh Keyboard"
        ))
        v.addArrangedSubview(actionButton("Open Settings", color: .systemBlue,
                                          target: self, action: #selector(openSettings)))
        return v
    }

    private func fontCard() -> UIView {
        let v = cardContainer(title: "FatemiMaqala Font")

        let preview = UILabel()
        preview.text = "كيم چهو؟!"
        preview.font = UIFont(name: "FatemiMaqala-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24)
        preview.textAlignment = .center
        v.addArrangedSubview(preview)

        v.addArrangedSubview(bodyLabel(
            "Install the font so Notes, Pages, Word, and other apps can " +
            "render Lisan ud Dawat text correctly."
        ))

        // Step-by-step instructions
        let steps = [
            "1.  Tap \"Save Profile\" below.",
            "2.  In the share sheet, choose Save to Files.",
            "3.  Open the Files app and tap FatemiMaqala.mobileconfig.",
            "4.  Follow the prompt:\nSettings → General → VPN & Device Management → FatemiMaqala Font → Install.",
        ]
        for step in steps {
            v.addArrangedSubview(bodyLabel(step))
        }

        installButton.configuration = Self.buttonConfiguration(title: "Save Profile", color: .systemBlue)
        installButton.addTarget(self, action: #selector(saveProfile), for: .touchUpInside)
        v.addArrangedSubview(installButton)

        v.addArrangedSubview(bodyLabel(
            "To uninstall: Settings → General → VPN & Device Management → FatemiMaqala Font → Remove Profile.\n" 
        ))

        return v
    }

    private func appearanceCard() -> UIView {
        let sharedDefaults = UserDefaults(suiteName: "group.com.exordiumnetworks.lsdkeyboard")
        let v = cardContainer(title: "Keyboard Appearance")

        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center

        let lbl = UILabel()
        lbl.text = "Angled keys"
        lbl.font = UIFont.systemFont(ofSize: 15)
        lbl.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let toggle = UISwitch()
        let stored = sharedDefaults?.object(forKey: "angled_keys_enabled") as? Bool
        toggle.isOn = stored ?? true
        toggle.addAction(UIAction { _ in
            sharedDefaults?.set(toggle.isOn, forKey: "angled_keys_enabled")
        }, for: .valueChanged)

        row.addArrangedSubview(lbl)
        row.addArrangedSubview(toggle)
        v.addArrangedSubview(row)
        v.addArrangedSubview(bodyLabel("Takes effect the next time the keyboard loads."))
        return v
    }

    private func corpusCard() -> UIView {
        let v = cardContainer(title: "Typing Data")
        v.addArrangedSubview(bodyLabel(
            "Exports lsd_corpus_words.json from the shared app group — " +
            "contains touch offsets, correction counts, and daily snapshots " +
            "tagged with the angled-keys condition."
        ))
        v.addArrangedSubview(actionButton("Export JSON", color: .systemGreen,
                                          target: self, action: #selector(exportCorpus)))
        return v
    }

    private func aboutCard() -> UIView {
        let v = cardContainer(title: "About")
        v.addArrangedSubview(bodyLabel(
            "LigaCheh is open source under the MIT License. View the licenses "
            + "for the bundled FatemiMaqala font and other components."
        ))
        v.addArrangedSubview(actionButton("Acknowledgements", color: .systemGray,
                                          target: self, action: #selector(showAcknowledgements)))
        return v
    }

    // MARK: - Actions

    @objc private func showAcknowledgements() {
        navigationController?.pushViewController(AcknowledgementsViewController(), animated: true)
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func saveProfile() {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("FatemiMaqala.mobileconfig")
        try? FileManager.default.removeItem(at: dest)

        if let signed = Bundle.main.url(forResource: "FatemiMaqala", withExtension: "mobileconfig") {
            // A pre-signed profile is bundled (see submission/sign-profile.sh) —
            // ship it as-is so the install screen shows "Verified".
            do {
                try FileManager.default.copyItem(at: signed, to: dest)
            } catch {
                alert("Could not prepare profile: \(error.localizedDescription)")
                return
            }
        } else {
            // No signed profile bundled — generate an unsigned one on the fly.
            guard
                let fontURL  = Bundle.main.url(forResource: "FatemiMaqala-Regular", withExtension: "ttf"),
                let fontData = try? Data(contentsOf: fontURL),
                let profile  = buildMobileconfig(fontData: fontData)
            else {
                alert("Font file not found in app bundle.")
                return
            }
            do {
                try profile.write(to: dest, options: .atomic)
            } catch {
                alert("Could not write profile: \(error.localizedDescription)")
                return
            }
        }

        let share = UIActivityViewController(activityItems: [dest], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = installButton
        present(share, animated: true)
    }

    @objc private func exportCorpus() {
        let groupID  = "group.com.exordiumnetworks.lsdkeyboard"
        let fileName = "lsd_corpus_words.json"

        // Prefer the shared App Group container; fall back to the extension's Documents.
        let candidates: [URL] = [
            FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier: groupID)?
                .appendingPathComponent(fileName),
            FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask).first?
                .appendingPathComponent(fileName),
        ].compactMap { $0 }

        guard let source = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) else {
            alert("No corpus data found yet — type a few words with the keyboard first.")
            return
        }

        // Copy to a temp location with a timestamped name so repeated exports are distinct.
        let stamp = ISO8601DateFormatter().string(from: Date()).prefix(10)
        let dest  = FileManager.default.temporaryDirectory
            .appendingPathComponent("lsd_corpus_\(stamp).json")
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: source, to: dest)
        } catch {
            alert("Could not copy corpus file: \(error.localizedDescription)")
            return
        }

        let share = UIActivityViewController(activityItems: [dest], applicationActivities: nil)
        share.popoverPresentationController?.sourceView = view
        present(share, animated: true)
    }

    // MARK: - Mobileconfig generation

    private func buildMobileconfig(fontData: Data) -> Data? {
        let fontPayload: [String: Any] = [
            "Font":                fontData,
            "PayloadDescription":  "FatemiMaqala typeface for LigaCheh",
            "PayloadDisplayName":  "FatemiMaqala",
            "PayloadIdentifier":   "com.exordiumnetworks.LisanUdDawat.font.FatemiMaqala",
            "PayloadOrganization": "LigaCheh",
            "PayloadType":         "com.apple.font",
            "PayloadUUID":         "B2C3D4E5-F6A7-8901-BCDE-F01234567890",
            "PayloadVersion":      1,
        ]
        let profile: [String: Any] = [
            "PayloadContent":          [fontPayload],
            "PayloadDescription":      "Installs FatemiMaqala so it is available in all apps",
            "PayloadDisplayName":      "FatemiMaqala Font",
            "PayloadIdentifier":       "com.exordiumnetworks.LisanUdDawat.fontprofile",
            "PayloadOrganization":     "LigaCheh",
            "PayloadRemovalDisallowed": false,
            "PayloadType":             "Configuration",
            "PayloadUUID":             "A1B2C3D4-E5F6-7890-ABCD-EF1234567890",
            "PayloadVersion":          1,
        ]
        return try? PropertyListSerialization.data(fromPropertyList: profile, format: .xml, options: 0)
    }

    // MARK: - Helpers

    private func alert(_ message: String) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func cardContainer(title: String) -> UIStackView {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 12
        v.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        v.isLayoutMarginsRelativeArrangement = true
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        let t = UILabel()
        t.text = title
        t.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        v.addArrangedSubview(t)
        return v
    }

    private func bodyLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UIFont.systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        return l
    }

    private func actionButton(_ title: String, color: UIColor, target: Any, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.configuration = Self.buttonConfiguration(title: title, color: color)
        btn.addTarget(target, action: action, for: .touchUpInside)
        return btn
    }

    /// Filled-style configuration shared by the app's action buttons
    /// (replaces the deprecated contentEdgeInsets/backgroundColor styling).
    private static func buttonConfiguration(title: String, color: UIColor) -> UIButton.Configuration {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = color
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0)
        config.background.cornerRadius = 10
        var attrTitle = AttributedString(title)
        attrTitle.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        config.attributedTitle = attrTitle
        return config
    }
}
