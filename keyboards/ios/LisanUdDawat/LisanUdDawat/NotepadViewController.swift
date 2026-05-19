import UIKit

// RTL text editor in FatemiMaqala font — practice typing with the keyboard
// and see how text renders. Content is saved to UserDefaults between sessions.

final class NotepadViewController: UIViewController, UITextViewDelegate {

    private let textView  = UITextView()
    private let countBar  = UILabel()
    private var countBarBottom: NSLayoutConstraint?

    private static let storageKey = "notepad_text"
    private static let fontSizeKey = "notepad_font_size"
    private static let defaultFontSize: CGFloat = 22

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notepad"
        view.backgroundColor = .systemBackground
        buildUI()
        loadContent()

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "trash"),
                            style: .plain, target: self, action: #selector(confirmClear)),
            UIBarButtonItem(image: UIImage(systemName: "textformat.size"),
                            style: .plain, target: self, action: #selector(showFontSizePicker)),
        ]
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        save()
    }

    // MARK: - UI

    private func buildUI() {
        // Text view
        textView.delegate = self
        textView.font = fatemiFont()
        textView.textAlignment = .right
        textView.semanticContentAttribute = .forceRightToLeft
        textView.autocorrectionType = .no
        textView.autocapitalizationType = .none
        textView.spellCheckingType = .no
        textView.backgroundColor = .systemBackground
        textView.textColor = .label
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        // Word / character count bar
        countBar.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        countBar.textColor = .tertiaryLabel
        countBar.textAlignment = .center
        countBar.backgroundColor = .systemBackground
        countBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(countBar)

        let barBottom = countBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        countBarBottom = barBottom

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: countBar.topAnchor),

            countBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            countBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            countBar.heightAnchor.constraint(equalToConstant: 28),
            barBottom,
        ])
    }

    // MARK: - Persistence

    private func loadContent() {
        textView.text = UserDefaults.standard.string(forKey: Self.storageKey) ?? ""
        updateCount()
    }

    private func save() {
        UserDefaults.standard.set(textView.text, forKey: Self.storageKey)
    }

    // MARK: - Actions

    @objc private func dismissKeyboard() {
        textView.resignFirstResponder()
    }

    @objc private func confirmClear() {
        let a = UIAlertController(title: "Clear notepad?", message: nil, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.textView.text = ""
            self?.save()
            self?.updateCount()
        })
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(a, animated: true)
    }

    @objc private func showFontSizePicker() {
        let current = UserDefaults.standard.object(forKey: Self.fontSizeKey) as? CGFloat
            ?? Self.defaultFontSize
        let a = UIAlertController(title: "Font Size", message: nil, preferredStyle: .actionSheet)
        for size: CGFloat in [16, 18, 20, 22, 24, 28, 32, 40] {
            let mark = size == current ? " ✓" : ""
            a.addAction(UIAlertAction(title: "\(Int(size)) pt\(mark)", style: .default) { [weak self] _ in
                UserDefaults.standard.set(size, forKey: Self.fontSizeKey)
                self?.textView.font = self?.fatemiFont()
            })
        }
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?.last
        present(a, animated: true)
    }

    // MARK: - UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        updateCount()
        save()
    }

    // MARK: - Keyboard avoidance

    @objc private func keyboardWillChange(_ note: Notification) {
        guard
            let frame    = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve    = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let overlap = max(0, view.bounds.maxY - frame.minY)
        let safeBot = view.safeAreaInsets.bottom
        let inset   = max(0, overlap - safeBot)

        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.textView.contentInset.bottom = inset
            self.textView.verticalScrollIndicatorInsets.bottom = inset
            self.countBarBottom?.constant = -(overlap > 0 ? overlap - safeBot : 0)
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Helpers

    private func fatemiFont() -> UIFont {
        let size = UserDefaults.standard.object(forKey: Self.fontSizeKey) as? CGFloat
            ?? Self.defaultFontSize
        return UIFont(name: "FatemiMaqala-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }

    private func updateCount() {
        let text  = textView.text ?? ""
        let chars = text.count
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        countBar.text = "\(words) words  ·  \(chars) chars"
    }
}
