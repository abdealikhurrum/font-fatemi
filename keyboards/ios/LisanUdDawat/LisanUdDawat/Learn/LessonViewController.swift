import UIKit

final class LessonViewController: UIViewController {

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
    private let bottomBar     = UIView()
    private let prevButton    = UIButton(type: .system)
    private let nextButton    = UIButton(type: .system)

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
    }

    // MARK: - Build UI

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
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

        // Target: displayed as a large reference example, not a typing prompt
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

        [progressLabel, headingLabel, bodyLabel, targetLabel, hintBadge]
            .forEach { contentStack.addArrangedSubview($0) }

        contentStack.setCustomSpacing(4, after: targetLabel)

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

    // MARK: - Render step

    private func render() {
        let step  = module.steps[stepIndex]
        let total = module.steps.count

        progressLabel.text = "Step \(stepIndex + 1) of \(total)"
        headingLabel.text  = step.heading
        bodyLabel.text     = step.body

        targetLabel.isHidden = step.target.isEmpty
        hintBadge.isHidden   = step.keyHint.isEmpty

        if !step.target.isEmpty  { targetLabel.text   = step.target }
        if !step.keyHint.isEmpty { hintBadge.text = "  \(step.keyHint)  " }

        prevButton.isEnabled = stepIndex > 0
        prevButton.alpha     = stepIndex > 0 ? 1 : 0.3

        let isLast = stepIndex == total - 1
        nextButton.setTitle(isLast ? "Finish" : "Continue →", for: .normal)
        nextButton.tintColor = module.accent

        scrollView.setContentOffset(.zero, animated: true)
    }

    // MARK: - Navigation

    @objc private func nextTapped() {
        if stepIndex < module.steps.count - 1 {
            stepIndex += 1
            render()
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc private func prevTapped() {
        guard stepIndex > 0 else { return }
        stepIndex -= 1
        render()
    }
}
