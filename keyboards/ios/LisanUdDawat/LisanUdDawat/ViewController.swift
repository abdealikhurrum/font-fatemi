import UIKit
import CoreText

final class ViewController: UIViewController {

    private lazy var scrollView       = UIScrollView()
    private lazy var stackView        = UIStackView()
    private lazy var fontStatusLabel  = UILabel()
    private lazy var installButton    = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Setup"
        view.backgroundColor = .systemGroupedBackground
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFontStatus()
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
        stackView.addArrangedSubview(fontCard())
    }

    // MARK: - Cards

    private func keyboardCard() -> UIView {
        let v = cardContainer(title: "Enable Keyboard")
        v.addArrangedSubview(bodyLabel(
            "Settings → General → Keyboard → Keyboards → " +
            "Add New Keyboard… → Lisan ud Dawat"
        ))
        let btn = actionButton("Open Settings", color: .systemBlue, target: self, action: #selector(openSettings))
        v.addArrangedSubview(btn)
        return v
    }

    private func fontCard() -> UIView {
        let v = cardContainer(title: "FatemiMaqala Font")
        v.addArrangedSubview(bodyLabel(
            "Install the font so other apps — Notes, Pages, Word — " +
            "can render Lisan ud Dawat text correctly."
        ))

        let preview = UILabel()
        preview.text = "اَلْبَيَانُ مِنَ الْإِيمَان"
        preview.font = UIFont(name: "FatemiMaqala-Regular", size: 24) ?? UIFont.systemFont(ofSize: 24)
        preview.textAlignment = .center
        preview.textColor = .label
        v.addArrangedSubview(preview)

        fontStatusLabel.font = UIFont.systemFont(ofSize: 14)
        fontStatusLabel.textAlignment = .center
        v.addArrangedSubview(fontStatusLabel)

        installButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        installButton.layer.cornerRadius = 10
        installButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        installButton.setTitleColor(.white, for: .normal)
        installButton.addTarget(self, action: #selector(installFont), for: .touchUpInside)
        v.addArrangedSubview(installButton)

        return v
    }

    // MARK: - Font status

    private func updateFontStatus() {
        let installed = isFontInstalled()
        fontStatusLabel.text      = installed ? "Installed — available in other apps" : "Not yet installed"
        fontStatusLabel.textColor = installed ? .systemGreen : .secondaryLabel
        installButton.setTitle(installed ? "Reinstall Font" : "Install Font", for: .normal)
        installButton.backgroundColor = installed ? .systemGray : .systemBlue
    }

    private func isFontInstalled() -> Bool {
        guard let descs = CTFontManagerCopyRegisteredFontDescriptors(.user, true) as? [CTFontDescriptor]
        else { return false }
        return descs.contains {
            (CTFontDescriptorCopyAttribute($0, kCTFontNameAttribute) as? String) == "FatemiMaqala-Regular"
        }
    }

    // MARK: - Actions

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    @objc private func installFont() {
        guard let url = Bundle.main.url(forResource: "FatemiMaqala-Regular", withExtension: "ttf") else {
            alert("Font file not found in app bundle.")
            return
        }
        installButton.isEnabled = false
        CTFontManagerRegisterFontURLs([url] as CFArray, .user, true) { [weak self] (errors, _) -> Bool in
            DispatchQueue.main.async {
                self?.installButton.isEnabled = true
                if let errs = errors as? [CFError], !errs.isEmpty {
                    let msg = errs.map { ($0 as Error).localizedDescription }.joined(separator: "\n")
                    self?.alert(msg)
                }
                self?.updateFontStatus()
            }
            return true
        }
    }

    private func alert(_ message: String) {
        let a = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Helpers

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
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = color
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 10
        btn.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        btn.addTarget(target, action: action, for: .touchUpInside)
        return btn
    }
}
