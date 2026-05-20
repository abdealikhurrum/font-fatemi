import UIKit

// Shown once when the user first opens the app or navigates to Corpus settings.
// Explains exactly what corpus contribution means, what is shared, and gives
// a clear opt-in / opt-out choice.  Never shown again after a decision is made
// unless the user explicitly resets their choice.

protocol ConsentViewControllerDelegate: AnyObject {
    func consentDidGrant()
    func consentDidDecline()
}

final class ConsentViewController: UIViewController {

    weak var delegate: ConsentViewControllerDelegate?

    // MARK: - Views

    private lazy var scrollView = UIScrollView()
    private lazy var stack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Word Contribution"
        view.backgroundColor = .systemGroupedBackground
        buildUI()
    }

    // MARK: - UI

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        stack.axis = .vertical
        stack.spacing = 20
        stack.layoutMargins = UIEdgeInsets(top: 28, left: 20, bottom: 40, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        stack.addArrangedSubview(heading("Help build the Lisan ud Dawat corpus"))

        stack.addArrangedSubview(section(
            icon: "📖",
            title: "What this is",
            body: """
            A Lisan ud Dawat language corpus is a collection of words and their \
            romanized equivalents. It helps train and improve transliteration for \
            everyone in the community.
            """
        ))

        stack.addArrangedSubview(section(
            icon: "👁",
            title: "What you see before anything is shared",
            body: """
            Nothing is sent without your review. When you use the keyboard, \
            word pairs are collected privately on your device. You can open the \
            review screen at any time to see exactly what has been collected, \
            approve individual pairs, or discard anything you're not comfortable sharing.
            """
        ))

        stack.addArrangedSubview(section(
            icon: "📤",
            title: "What is actually shared",
            body: """
            Only the word pairs you explicitly approve: for example,
            { "lsd": "بِسمِ", "roman": "bismi" }.

            No metadata, no timestamps, no device information, \
            no surrounding context is included.
            """
        ))

        stack.addArrangedSubview(section(
            icon: "🔒",
            title: "What is never shared",
            body: """
            • Full sentences or passages
            • Anything you type but do not approve
            • Any word pair you discard
            • Your name, Apple ID, or any identifier

            You can delete all locally stored pairs at any time from the \
            review screen, and withdraw consent at any time from Settings.
            """
        ))

        stack.addArrangedSubview(section(
            icon: "📚",
            title: "Where the corpus goes",
            body: """
            Approved pairs are shared with the community project and may \
            eventually be published as an open dataset to benefit Lisan ud Dawat \
            digital tools broadly. The dataset will not be linked to individuals.
            """
        ))

        // Example pair
        stack.addArrangedSubview(exampleCard())

        // Action buttons
        let joinBtn = actionButton(
            "Yes, I'll contribute words",
            color: .systemBlue,
            action: #selector(grant)
        )
        let skipBtn = actionButton(
            "No thanks",
            color: .systemGray,
            action: #selector(decline)
        )
        stack.addArrangedSubview(joinBtn)
        stack.addArrangedSubview(skipBtn)

        let note = label(
            "You can change this decision at any time in Settings → Word Contribution.",
            size: 13, color: .tertiaryLabel
        )
        note.textAlignment = .center
        stack.addArrangedSubview(note)
    }

    // MARK: - Actions

    @objc private func grant() {
        CorpusManager.shared.consentState = .granted
        delegate?.consentDidGrant()
        dismiss(animated: true)
    }

    @objc private func decline() {
        CorpusManager.shared.consentState = .declined
        delegate?.consentDidDecline()
        dismiss(animated: true)
    }

    // MARK: - Helpers

    private func heading(_ text: String) -> UILabel {
        label(text, size: 22, weight: .bold)
    }

    private func section(icon: String, title: String, body: String) -> UIView {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 6
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        v.isLayoutMarginsRelativeArrangement = true

        let header = UIStackView()
        header.axis = .horizontal
        header.spacing = 8
        let iconLabel = label(icon, size: 20)
        let titleLabel = label(title, size: 15, weight: .semibold)
        header.addArrangedSubview(iconLabel)
        header.addArrangedSubview(titleLabel)
        v.addArrangedSubview(header)
        v.addArrangedSubview(label(body, size: 14, color: .secondaryLabel))
        return v
    }

    private func exampleCard() -> UIView {
        let v = UIStackView()
        v.axis = .vertical
        v.spacing = 8
        v.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.08)
        v.layer.cornerRadius = 12
        v.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        v.isLayoutMarginsRelativeArrangement = true

        v.addArrangedSubview(label("Example pair you might contribute:", size: 13, color: .secondaryLabel))

        let lsdLabel = label("بِسمِ", size: 22)
        lsdLabel.textAlignment = .right
        lsdLabel.semanticContentAttribute = .forceRightToLeft

        let arrow = label("→  bismi", size: 17, color: .secondaryLabel)

        let row = UIStackView(arrangedSubviews: [lsdLabel, arrow])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        v.addArrangedSubview(row)

        return v
    }

    private func actionButton(_ title: String, color: UIColor, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        btn.backgroundColor = color
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 0, bottom: 14, right: 0)
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
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
}
