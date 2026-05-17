import UIKit

final class KeyboardViewController: UIInputViewController {

    // MARK: - Layer state

    private enum Layer { case `default`, shift, numeric }

    private var currentLayer: Layer = .default {
        didSet { applyLayer() }
    }
    private var shiftActive = false {
        didSet { keyboardView.updateShiftAppearance(active: shiftActive, locked: shiftLocked) }
    }
    private var shiftLocked = false

    // MARK: - Views

    private var keyboardView   = KeyboardView()
    private var predictiveBar  = PredictiveBar()

    // MARK: - Double-space tracking

    private var lastInsertedCharacter: Character?
    private var lastInsertTime: Date?
    private static let doubleSpaceWindow: TimeInterval = 0.4

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUI()
        applyLayer()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Proper keyboard height: predictive bar + key area + bottom safe area
        let keyH   = keyboardView.intrinsicContentSize.height
        let barH   = PredictiveBar.height
        let safeB  = view.safeAreaInsets.bottom
        let total  = keyH + barH + safeB
        view.frame.size.height = total
    }

    // MARK: - Setup

    private func buildUI() {
        view.backgroundColor = UIColor(white: 0.82, alpha: 1)

        predictiveBar.delegate = self
        predictiveBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(predictiveBar)

        keyboardView.delegate = self
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)

        NSLayoutConstraint.activate([
            predictiveBar.topAnchor.constraint(equalTo: view.topAnchor),
            predictiveBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            predictiveBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            predictiveBar.heightAnchor.constraint(equalToConstant: PredictiveBar.height),

            keyboardView.topAnchor.constraint(equalTo: predictiveBar.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func applyLayer() {
        switch currentLayer {
        case .default:  keyboardView.configure(with: KeyboardLayoutData.defaultLayer)
        case .shift:    keyboardView.configure(with: KeyboardLayoutData.shiftLayer)
        case .numeric:  keyboardView.configure(with: KeyboardLayoutData.numericLayer)
        }
        // Refresh shift indicator after reconfigure
        keyboardView.updateShiftAppearance(active: shiftActive, locked: shiftLocked)
    }

    // MARK: - Text insertion

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        lastInsertedCharacter = text.last
        lastInsertTime = Date()
        updatePredictions()
    }

    private func deleteBack() {
        textDocumentProxy.deleteBackward()
        lastInsertedCharacter = nil
        updatePredictions()
    }

    // MARK: - Predictions
    // Feed real results from the transliteration model here.
    // For now, surfaces context from the document proxy as a placeholder.

    private func updatePredictions() {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let word    = context.components(separatedBy: .whitespaces).last ?? ""

        if word.isEmpty {
            predictiveBar.update(suggestions: [])
        } else {
            // Placeholder — replace with model inference
            predictiveBar.update(suggestions: [word, word + "ا", word + "ه"])
        }
    }
}

// MARK: - KeyboardViewDelegate

extension KeyboardViewController: KeyboardViewDelegate {

    func keyPressed(_ key: KeyData) {
        switch key.type {

        case .character:
            insert(key.primary)
            if shiftActive && !shiftLocked {
                shiftActive  = false
                currentLayer = .default
            }

        case .space:
            // Double-space → period + space, matching iOS native behaviour
            let now = Date()
            if let last = lastInsertedCharacter,
               let lastTime = lastInsertTime,
               last != " " && last != "\n",
               now.timeIntervalSince(lastTime) < Self.doubleSpaceWindow,
               textDocumentProxy.documentContextBeforeInput?.last?.isLetter == true {
                textDocumentProxy.deleteBackward()   // remove trailing space if any
                textDocumentProxy.insertText(". ")
            } else {
                insert(" ")
            }

        case .backspace:
            deleteBack()

        case .enter:
            insert("\n")

        case .shift:
            switch (currentLayer, shiftActive, shiftLocked) {
            case (.default, false, _):
                // First tap: shift on
                currentLayer = .shift
                shiftActive  = true
                shiftLocked  = false
            case (.shift, true, false):
                // Second tap: caps lock
                shiftLocked = true
                keyboardView.updateShiftAppearance(active: true, locked: true)
            case (.shift, true, true):
                // Third tap: off
                currentLayer = .default
                shiftActive  = false
                shiftLocked  = false
            default:
                break
            }

        case .numeric:
            currentLayer = .numeric
            shiftActive  = false
            shiftLocked  = false

        case .abc:
            currentLayer = .default
            shiftActive  = false
            shiftLocked  = false

        case .globe:
            advanceToNextInputMode()
        }
    }

    func longPressAlternateSelected(_ character: String) {
        insert(character)
        if shiftActive && !shiftLocked {
            shiftActive  = false
            currentLayer = .default
        }
    }

    // Pair collection hooks (connect to PairCollector when model is live)
    func transliterationAccepted(lsd: String, roman: String) {
        PairCollector.shared.recordAccepted(lsd: lsd, roman: roman)
    }

    func transliterationCorrected(lsd: String, suggested: String, corrected: String) {
        PairCollector.shared.recordCorrection(lsd: lsd, suggestedRoman: suggested, correctedRoman: corrected)
    }
}

// MARK: - PredictiveBarDelegate

extension KeyboardViewController: PredictiveBarDelegate {
    func predictiveBar(_ bar: PredictiveBar, didSelect suggestion: String) {
        // Delete the partial word and insert the full suggestion
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let partial = before.components(separatedBy: .whitespaces).last ?? ""
        for _ in partial { textDocumentProxy.deleteBackward() }
        insert(suggestion + " ")
    }
}
