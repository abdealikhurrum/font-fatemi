import UIKit
import CoreText

final class KeyboardViewController: UIInputViewController {

    // MARK: - Layer state

    private enum Layer { case `default`, numeric, diacritic }

    private var currentLayer: Layer = .default {
        didSet { applyLayer() }
    }

    // MARK: - Views

    private var keyboardView  = KeyboardView()
    private var predictiveBar = PredictiveBar()

    // MARK: - Double-space tracking

    private var lastInsertedCharacter: Character?
    private var lastInsertTime: Date?
    private static let doubleSpaceWindow: TimeInterval = 0.4

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        registerBundledFonts()
        buildUI()
        applyLayer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        CorpusLogger.shared.flush()
    }

    private static var fontsRegistered = false

    private func registerBundledFonts() {
        guard !Self.fontsRegistered else { return }
        // Run off the main thread — CTFontManagerRegisterFontsForURL does IPC with
        // fontservicesd which takes ~1s in a sandboxed extension on first call.
        // The keyboard builds immediately with a system-font fallback; once the
        // real font is ready we invalidate the cache and refresh key labels.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer { Self.fontsRegistered = true }
            guard UIFont(name: "FatemiMaqala-Regular", size: 12) == nil else { return }
            for ext in ["ttf", "otf", "TTF", "OTF"] {
                let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
                for url in urls {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                }
            }
            DispatchQueue.main.async {
                KeyButton.invalidateFontCache()
                self?.keyboardView.refreshKeyFonts()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let keyH  = keyboardView.intrinsicContentSize.height
        let safeB = view.safeAreaInsets.bottom
        view.frame.size.height = keyH + PredictiveBar.height + safeB
    }

    // MARK: - Setup

    private func buildUI() {
        view.backgroundColor = KeyboardColors.background

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
        case .default:   keyboardView.configure(with: KeyboardLayoutData.defaultLayer)
        case .numeric:   keyboardView.configure(with: KeyboardLayoutData.numericLayer)
        case .diacritic: keyboardView.configure(with: KeyboardLayoutData.diacriticLayer)
        }
    }

    // MARK: - Text insertion

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        lastInsertedCharacter = text.last
        lastInsertTime = Date()
        if KeyboardSettings.corpusEnabled { CorpusLogger.shared.record(text) }
        updatePredictions()
    }

    private func deleteBack() {
        textDocumentProxy.deleteBackward()
        lastInsertedCharacter = nil
        CorpusLogger.shared.recordBackspace()
        updatePredictions()
    }

    // MARK: - Predictions

    private func updatePredictions() {
        guard KeyboardSettings.predictionEnabled else {
            predictiveBar.update(suggestions: [])
            return
        }
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        let word    = context.components(separatedBy: .whitespaces).last ?? ""
        if word.isEmpty {
            predictiveBar.update(suggestions: [])
        } else {
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

        case .space:
            // Double-space → period + space (user pressed space twice quickly)
            let now = Date()
            if lastInsertedCharacter == " ",
               let lastTime = lastInsertTime,
               now.timeIntervalSince(lastTime) < Self.doubleSpaceWindow {
                // Confirm the char before the already-inserted space is a letter
                let ctx = textDocumentProxy.documentContextBeforeInput ?? ""
                if ctx.dropLast().last?.isLetter == true {
                    textDocumentProxy.deleteBackward()
                    insert(". ")
                } else {
                    insert(" ")
                }
            } else {
                insert(" ")
            }

        case .backspace:
            deleteBack()

        case .enter:
            insert("\n")

        case .numeric:
            currentLayer = .numeric

        case .diacritic:
            currentLayer = .diacritic

        case .abc:
            currentLayer = .default

        case .cursorLeft:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -1)

        case .cursorRight:
            textDocumentProxy.adjustTextPosition(byCharacterOffset: 1)

        case .globe:
            advanceToNextInputMode()

        case .emoji:
            advanceToNextInputMode()
        }
    }

    func doubleTapPressed(on key: KeyData) {
        guard KeyboardSettings.doubleTapEnabled else { return }
        deleteBack()           // removes primary from both proxy and pendingWord
        insert(key.secondary)
    }

    func longPressAlternateSelected(_ character: String) {
        insert(character)
    }

    func backspaceWordPressed() {
        let context = textDocumentProxy.documentContextBeforeInput ?? ""
        guard !context.isEmpty else { return }

        var deleteCount = 0
        var hitWord = false
        for ch in context.reversed() {
            if !hitWord {
                deleteCount += 1
                if !ch.isWhitespace { hitWord = true }
            } else {
                if ch.isWhitespace { break }
                deleteCount += 1
            }
        }
        for _ in 0..<deleteCount { textDocumentProxy.deleteBackward() }
        lastInsertedCharacter = nil
        CorpusLogger.shared.resetPending()   // word-delete may erase the in-progress word
        updatePredictions()
    }

    // Pair collection hooks
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
        let before  = textDocumentProxy.documentContextBeforeInput ?? ""
        let partial = before.components(separatedBy: .whitespaces).last ?? ""
        for _ in partial { textDocumentProxy.deleteBackward() }
        insert(suggestion + " ")
    }

    func predictiveBarDidTapSettings(_ bar: PredictiveBar) {
        KeyboardMenuView.show(in: view)
    }
}
