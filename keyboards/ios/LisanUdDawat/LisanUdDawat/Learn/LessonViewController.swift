import UIKit

final class LessonViewController: UIViewController, UITextFieldDelegate {

    private let module: LessonModule
    private var stepIndex = 0

    // UI
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()
    private let progressLabel = UILabel()
    private let headingLabel  = UILabel()
    private let bodyLabel     = UILabel()
    private let targetLabel   = UILabel()
    private let hintBadge     = UILabel()
    private let inputField    = UITextField()
    private let feedbackLabel = UILabel()
    private let bottomBar     = UIView()
    private let prevButton    = UIButton(type: .system)
    private let nextButton    = UIButton(type: .system)

    private var bottomBarBottom: NSLayoutConstraint?
    private var advanceTimer: Timer?

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputField.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        advanceTimer?.invalidate()
    }

    // MARK: - Build UI

    private func buildUI() {
        // Scroll area
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Progress
        progressLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .medium)
        progressLabel.textColor = .tertiaryLabel
        progressLabel.textAlignment = .center

        // Heading
        headingLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        headingLabel.adjustsFontForContentSizeCategory = true
        headingLabel.numberOfLines = 0
        headingLabel.textAlignment = .right

        // Body
        bodyLabel.font = UIFont.preferredFont(forTextStyle: .body)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .natural
        bodyLabel.textColor = .secondaryLabel

        // Target word (big Arabic text)
        targetLabel.font = UIFont(name: "FatemiMaqala-Regular", size: 42)
            ?? UIFont.systemFont(ofSize: 42)
        targetLabel.textAlignment = .center
        targetLabel.textColor = .label
        targetLabel.numberOfLines = 1
        targetLabel.adjustsFontSizeToFitWidth = true
        targetLabel.minimumScaleFactor = 0.6

        // Hint badge
        hintBadge.font = UIFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        hintBadge.textAlignment = .center
        hintBadge.layer.cornerRadius = 8
        hintBadge.layer.masksToBounds = true
        hintBadge.textColor = module.accent
        hintBadge.backgroundColor = module.accent.withAlphaComponent(0.12)

        // Input field (hidden — exists only to receive keyboard input)
        inputField.delegate = self
        inputField.autocorrectionType = .no
        inputField.autocapitalizationType = .none
        inputField.spellCheckingType = .no
        inputField.inputAssistantItem.leadingBarButtonGroups = []
        inputField.inputAssistantItem.trailingBarButtonGroups = []
        // Invisible but tappable; keyboard appears via becomeFirstResponder
        inputField.textColor = .clear
        inputField.tintColor = .clear
        inputField.backgroundColor = .clear
        inputField.heightAnchor.constraint(equalToConstant: 1).isActive = true
        inputField.addTarget(self, action: #selector(inputChanged), for: .editingChanged)

        // Feedback ("✓ Correct!")
        feedbackLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        feedbackLabel.textAlignment = .center
        feedbackLabel.alpha = 0

        // Assemble stack
        [progressLabel, headingLabel, bodyLabel, targetLabel, hintBadge, inputField, feedbackLabel]
            .forEach { contentStack.addArrangedSubview($0) }

        contentStack.setCustomSpacing(4, after: targetLabel)
        contentStack.setCustomSpacing(12, after: hintBadge)

        // Bottom bar (Prev / Next)
        bottomBar.backgroundColor = .systemBackground
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bottomBar)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(separator)

        prevButton.setTitle("← Back", for: .normal)
        nextButton.setTitle("Continue →", for: .normal)
        nextButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)

        let buttonRow = UIStackView(arrangedSubviews: [prevButton, nextButton])
        buttonRow.axis = .horizontal
        buttonRow.distribution = .equalSpacing
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addSubview(buttonRow)

        prevButton.addTarget(self, action: #selector(prevTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        let barBottom = bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomBarBottom = barBottom

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
            barBottom,

            separator.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            separator.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            buttonRow.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            buttonRow.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            buttonRow.centerYAnchor.constraint(equalTo: bottomBar.centerYAnchor),
        ])
    }

    // MARK: - Render step

    private func render() {
        advanceTimer?.invalidate()
        let step = module.steps[stepIndex]
        let total = module.steps.count

        progressLabel.text = "Step \(stepIndex + 1) of \(total)"

        headingLabel.text = step.heading

        bodyLabel.text = step.body

        let isExercise = !step.target.isEmpty
        targetLabel.isHidden = !isExercise
        hintBadge.isHidden   = step.keyHint.isEmpty
        inputField.isHidden  = !isExercise
        feedbackLabel.isHidden = !isExercise

        if isExercise {
            targetLabel.text = step.target
            hintBadge.text = "  \(step.keyHint)  "
            inputField.text = ""
            feedbackLabel.text = ""
            feedbackLabel.alpha = 0
            inputField.becomeFirstResponder()
        }

        prevButton.isEnabled = stepIndex > 0
        prevButton.alpha = stepIndex > 0 ? 1 : 0.3

        let isLast = stepIndex == total - 1
        nextButton.setTitle(isLast ? "Finish" : (isExercise ? "Skip →" : "Continue →"), for: .normal)
        nextButton.tintColor = isExercise ? .secondaryLabel : module.accent

        // Scroll to top
        scrollView.setContentOffset(.zero, animated: true)
    }

    // MARK: - Input handling

    @objc private func inputChanged() {
        guard !module.steps[stepIndex].target.isEmpty else { return }
        let typed  = inputField.text ?? ""
        let target = module.steps[stepIndex].target

        if typed == target {
            showCorrect()
        } else if target.hasPrefix(typed) {
            // Still building towards the answer — show neutral feedback
            feedbackLabel.text = ""
            feedbackLabel.alpha = 0
        } else {
            // Wrong — let user keep editing, no penalty
        }
    }

    private func showCorrect() {
        feedbackLabel.text = "✓  Correct!"
        feedbackLabel.textColor = module.accent
        UIView.animate(withDuration: 0.2) { self.feedbackLabel.alpha = 1 }

        // Haptic
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Auto-advance after short delay
        advanceTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            self?.advance()
        }
    }

    // MARK: - Navigation

    @objc private func nextTapped() {
        advance()
    }

    @objc private func prevTapped() {
        guard stepIndex > 0 else { return }
        stepIndex -= 1
        render()
    }

    private func advance() {
        advanceTimer?.invalidate()
        if stepIndex < module.steps.count - 1 {
            stepIndex += 1
            render()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        advance()
        return false
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
        let shift   = overlap > 0 ? overlap - safeBot : 0

        UIView.animate(withDuration: duration, delay: 0,
                       options: UIView.AnimationOptions(rawValue: curve << 16)) {
            self.bottomBarBottom?.constant = -shift
            self.view.layoutIfNeeded()
        }
    }
}
