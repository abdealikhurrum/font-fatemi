import UIKit

final class LessonViewController: UIViewController, UITextViewDelegate {

    private let module: LessonModule
    private var stepIndex = 0

    // UI
    private let scrollView    = UIScrollView()
    private let contentStack  = UIStackView()
    private let progressLabel = UILabel()
    private let headingLabel  = UILabel()
    private let bodyLabel     = UILabel()
    private let targetLabel   = UILabel()
    private let hintBadge     = UILabel()
    private let scratchCard   = UIView()
    private let scratchView   = UITextView()
    private let clearButton   = UIButton(type: .system)
    private let bottomBar     = UIView()
    private let prevButton    = UIButton(type: .system)
    private let nextButton    = UIButton(type: .system)

    private static let scratchPlaceholder = "Try typing here…"

    init(module: LessonModule) {
        self.module = module
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = module.title
        view.backgroundColor = .systemGroupedBackground
        buildUI()
        render()
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scratchView.resignFirstResponder()
    }

    // MARK: - Build UI

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode  = .interactive
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        progressLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        progressLabel.textColor = .tertiaryLabel
        progressLabel.textAlignment = .center

        headingLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        headingLabel.adjustsFontForContentSizeCategory = true
        headingLabel.numberOfLines = 0
        headingLabel.textAlignment = .right

        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .natural
        bodyLabel.textColor = .secondaryLabel

        targetLabel.font = UIFont(name: "FatemiMaqala-Regular", size: 42)
            ?? UIFont.systemFont(ofSize: 42)
        targetLabel.textAlignment = .center
        targetLabel.textColor = .label
        targetLabel.numberOfLines = 1
        targetLabel.adjustsFontSizeToFitWidth = true
        targetLabel.minimumScaleFactor = 0.6

        hintBadge.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        hintBadge.textAlignment = .center
        hintBadge.layer.cornerRadius = 8
        hintBadge.layer.masksToBounds = true
        hintBadge.textColor = module.accent
        hintBadge.backgroundColor = module.accent.withAlphaComponent(0.12)

        buildScratchCard()

        [progressLabel, headingLabel, bodyLabel, targetLabel, hintBadge, scratchCard]
            .forEach { contentStack.addArrangedSubview($0) }

        contentStack.setCustomSpacing(4,  after: targetLabel)
        contentStack.setCustomSpacing(20, after: hintBadge)

        // Bottom bar
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(separator)

        prevButton.setTitle("← Back", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

        let buttonRow = UIStackView(arrangedSubviews: [prevButton, nextButton])
        buttonRow.axis         = .horizontal
        buttonRow.distribution = .equalSpacing
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(buttonRow)

        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.heightAnchor.constraint(equalToConstant: 56),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            separator.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            buttonRow.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            buttonRow.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            buttonRow.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
        ])
    }

    private func buildScratchCard() {
        scratchCard.backgroundColor    = .secondarySystemGroupedBackground
        scratchCard.layer.cornerRadius = 12
        scratchCard.layer.masksToBounds = true
        scratchCard.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text      = "Practice"
        label.font      = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .tertiaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        scratchCard.addSubview(label)

        clearButton.setTitle("Clear", for: .normal)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.addTarget(self, action: #selector(clearScratch), for: .touchUpInside)
        scratchCard.addSubview(clearButton)

        scratchView.delegate        = self
        scratchView.font            = UIFont(name: "FatemiMaqala-Regular", size: 28) ?? UIFont.systemFont(ofSize: 28)
        scratchView.textAlignment   = .right
        scratchView.backgroundColor = .clear
        scratchView.text            = Self.scratchPlaceholder
        scratchView.textColor       = .placeholderText
        scratchView.autocorrectionType     = .no
        scratchView.autocapitalizationType = .none
        scratchView.spellCheckingType      = .no
        scratchView.isScrollEnabled = false
        scratchView.translatesAutoresizingMaskIntoConstraints = false
        scratchCard.addSubview(scratchView)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: scratchCard.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: scratchCard.leadingAnchor, constant: 12),

            clearButton.topAnchor.constraint(equalTo: scratchCard.topAnchor, constant: 6),
            clearButton.trailingAnchor.constraint(equalTo: scratchCard.trailingAnchor, constant: -8),

            scratchView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            scratchView.leadingAnchor.constraint(equalTo: scratchCard.leadingAnchor, constant: 8),
            scratchView.trailingAnchor.constraint(equalTo: scratchCard.trailingAnchor, constant: -8),
            scratchView.bottomAnchor.constraint(equalTo: scratchCard.bottomAnchor, constant: -8),
            scratchView.heightAnchor.constraint(greaterThanOrEqualToConstant: 80),
        ])
    }

    // MARK: - Render step

    private func render() {
        let step  = module.steps[stepIndex]
        let total = module.steps.count

        progressLabel.text = "Step \(stepIndex + 1) of \(total)"
        headingLabel.text  = step.heading
        bodyLabel.text     = step.body

        targetLabel.isHidden = step.target.isEmpty
        hintBadge.isHidden   = step.keyHint.isEmpty

        if !step.target.isEmpty  { targetLabel.text       = step.target }
        if !step.keyHint.isEmpty { hintBadge.text         = "  \(step.keyHint)  " }

        resetScratch()

        prevButton.isEnabled = stepIndex > 0
        prevButton.alpha     = stepIndex > 0 ? 1 : 0.3

        let isLast = stepIndex == total - 1
        nextButton.setTitle(isLast ? "Finish" : "Continue →", for: .normal)
        nextButton.tintColor = module.accent

        scrollView.setContentOffset(.zero, animated: true)
    }

    // MARK: - Scratch pad

    private func resetScratch() {
        scratchView.text      = Self.scratchPlaceholder
        scratchView.textColor = .placeholderText
    }

    @objc private func clearScratch() {
        resetScratch()
        scratchView.resignFirstResponder()
    }

    // MARK: - UITextViewDelegate

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text      = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resetScratch()
        }
    }

    // MARK: - Navigation

    @objc private func nextTapped() {
        scratchView.resignFirstResponder()
        if stepIndex < module.steps.count - 1 {
            stepIndex += 1
            render()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func prevTapped() {
        guard stepIndex > 0 else { return }
        scratchView.resignFirstResponder()
        stepIndex -= 1
        render()
    }

    // MARK: - Keyboard avoidance

    @objc private func keyboardWillChange(_ note: Notification) {
        guard
            let frame    = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
            let curve    = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        let overlap = max(0, view.bounds.maxY - frame.minY)
        UIView.animate(withDuration: duration, delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.scrollView.contentInset.bottom = overlap
            self.scrollView.verticalScrollIndicatorInsets.bottom = overlap
        }
    }
}
