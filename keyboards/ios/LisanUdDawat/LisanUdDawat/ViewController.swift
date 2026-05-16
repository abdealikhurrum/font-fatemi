import UIKit

// Minimal container app — just instructs the user to enable the keyboard in Settings.
final class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)

        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17)
        label.text = """
        لسان الدعوت — Lisan ud Dawat Keyboard

        To activate the keyboard:
        Settings → General → Keyboard → Keyboards → Add New Keyboard…
        → Lisan ud Dawat
        """

        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        let btn = UIButton(type: .system)
        btn.setTitle("Open Settings", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btn)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),

            btn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            btn.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24),
        ])
    }

    @objc private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
