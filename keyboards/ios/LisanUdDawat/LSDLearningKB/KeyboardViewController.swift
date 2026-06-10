import UIKit
import CoreText

final class KeyboardViewController: UIInputViewController {

    // MARK: - Layer state

    private enum Layer { case `default`, numeric, diacritic, latin }

    private var currentLayer: Layer = .default {
        didSet { applyLayer() }
    }

    // Remembers the layer that was active before entering numeric/diacritic,
    // so ABC returns to latin rather than default when appropriate.
    private var priorToModal: Layer = .default

    // MARK: - Latin layer shift / caps-lock state

    private var latinShifted  = false
    private var latinCapsLock = false
    private var lastShiftTime: Date?

    // MARK: - Views

    private var keyboardView  = KeyboardView()
    private var predictiveBar = PredictiveBar()
    private var predictiveBarHeightConstraint: NSLayoutConstraint?
    private var biDiMenu: BiDiFixMenu?

    // MARK: - Double-space tracking

    private var lastInsertedCharacter: Character?
    private var lastInsertTime: Date?
    private static let doubleSpaceWindow: TimeInterval = 0.4

    // Set while ۚ was just auto-inserted; cleared on the next keystroke or backspace.
    private var jeemRevertPending = false

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
        CorpusLogger.shared.persistOffsets()
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
        updateLayout(for: UIScreen.main.bounds.size)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { [weak self] _ in
            self?.updateLayout(for: size)
        })
    }

    private func updateLayout(for screenSize: CGSize) {
        let isLandscape = screenSize.width > screenSize.height
        let m = isLandscape ? KeyboardMetrics.landscape : KeyboardMetrics.portrait
        keyboardView.metrics = m
        predictiveBarHeightConstraint?.constant = m.barHeight
        let safeB = view.safeAreaInsets.bottom
        view.frame.size.height = keyboardView.intrinsicContentSize.height + m.barHeight + safeB
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

        let barH = predictiveBar.heightAnchor.constraint(equalToConstant: PredictiveBar.height)
        predictiveBarHeightConstraint = barH

        NSLayoutConstraint.activate([
            predictiveBar.topAnchor.constraint(equalTo: view.topAnchor),
            predictiveBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            predictiveBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            barH,

            keyboardView.topAnchor.constraint(equalTo: predictiveBar.bottomAnchor),
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    private func applyLayer() {
        switch currentLayer {
        case .default:
            keyboardView.configure(with: activeDefaultLayer())
        case .numeric:
            keyboardView.configure(with: KeyboardLayoutData.numericLayer)
        case .diacritic:
            keyboardView.configure(with: KeyboardLayoutData.diacriticLayer)
        case .latin:
            keyboardView.configure(with: latinShifted ? LatinLayoutData.upperLayer : LatinLayoutData.lowerLayer)
        }
    }

    private func activeDefaultLayer() -> KeyboardLayer {
        switch KeyboardSettings.selectedLayout {
        case .lsd:            return KeyboardLayoutData.defaultLayer
        case .arabicStandard: return ArabicStandardLayoutData.defaultLayer
        case .crulpUrdu:      return CRULPUrduLayoutData.defaultLayer
        }
    }

    // MARK: - Text insertion

    private func insert(_ text: String) {
        jeemRevertPending = false
        textDocumentProxy.insertText(text)
        lastInsertedCharacter = text.last
        lastInsertTime = Date()
        if KeyboardSettings.corpusEnabled { CorpusLogger.shared.record(text) }
        updatePredictions()
        updateBiDi()
    }

    private func isIsolatedJeem(_ context: String) -> Bool {
        guard context.last == "ج" else { return false }
        let before = context.dropLast()
        return before.isEmpty || before.last?.isWhitespace == true
    }

    private func deleteBack() {
        jeemRevertPending = false
        if let char = lastInsertedCharacter,
           char.isLetter,
           let t = lastInsertTime,
           Date().timeIntervalSince(t) < 0.6 {
            CorpusLogger.shared.recordCorrection(for: String(char))
        }
        textDocumentProxy.deleteBackward()
        lastInsertedCharacter = nil
        CorpusLogger.shared.recordBackspace()
        updatePredictions()
        updateBiDi()
    }

    // MARK: - Predictions

    private func updatePredictions() {
        if jeemRevertPending {
            predictiveBar.update(suggestions: ["ج"])
            return
        }
        guard KeyboardSettings.predictionEnabled else {
            predictiveBar.update(suggestions: [])
            return
        }
        let context  = textDocumentProxy.documentContextBeforeInput ?? ""
        let parts    = context.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let word     = parts.last ?? ""
        let previous = parts.count >= 2 ? parts[parts.count - 2] : ""
        if word.isEmpty {
            predictiveBar.update(suggestions: [])
        } else {
            predictiveBar.update(suggestions: CorpusLogger.shared.suggestions(for: word, after: previous, limit: 3))
        }
    }

    // MARK: - BiDi

    private func updateBiDi() {
        let text = textDocumentProxy.documentContextBeforeInput ?? ""
        predictiveBar.updateBiDi(text)
    }

    private func showBiDiMenu(issue: BiDiAnalyzer.Issue) {
        guard biDiMenu == nil else { return }
        let menu = BiDiFixMenu.show(in: view, issue: issue)
        menu.onFixApplied = { [weak self] fix in
            guard let self else { return }
            switch fix {
            case .smart:
                BiDiAnalyzer.applySmartFix(issue: issue, proxy: self)
            case .fixLine:
                BiDiAnalyzer.insertRlmAtLineStart(proxy: self)
            case .fixAtCursor:
                BiDiAnalyzer.insertRlmAtCursor(proxy: self)
            case .markSelectionLTR:
                BiDiAnalyzer.wrapSelectionAsLtr(proxy: self)
            }
            self.predictiveBar.showBriefMessage("Direction mark added  ·  backspace to undo")
            self.updateBiDi()
        }
        menu.onDismiss = { [weak self] in self?.biDiMenu = nil }
        biDiMenu = menu
    }
}

// MARK: - BiDiTextProxy

extension KeyboardViewController: BiDiTextProxy {
    var textBeforeCursor: String {
        textDocumentProxy.documentContextBeforeInput ?? ""
    }
    var selectedText: String? {
        textDocumentProxy.selectedText
    }
    func deleteBeforeCursor(_ count: Int) {
        for _ in 0..<count { textDocumentProxy.deleteBackward() }
    }
    func insertAtCursor(_ text: String) {
        textDocumentProxy.insertText(text)
    }
}

// MARK: - KeyboardViewDelegate

extension KeyboardViewController: KeyboardViewDelegate {

    func keyPressed(_ key: KeyData) {
        switch key.type {

        case .character:
            insert(key.primary)
            // Auto-unshift after one letter in non-caps shifted Latin mode
            if currentLayer == .latin && latinShifted && !latinCapsLock {
                latinShifted = false
                applyLayer()
            }

        case .space:
            let spaceCtx = textDocumentProxy.documentContextBeforeInput ?? ""
            if isIsolatedJeem(spaceCtx) {
                textDocumentProxy.deleteBackward()
                textDocumentProxy.insertText("\u{06DA} ")
                lastInsertedCharacter = " "
                lastInsertTime = Date()
                if KeyboardSettings.corpusEnabled { CorpusLogger.shared.record("\u{06DA} ") }
                jeemRevertPending = true
                updatePredictions()
                updateBiDi()
                return
            }
            let now = Date()
            if lastInsertedCharacter == " ",
               let lastTime = lastInsertTime,
               now.timeIntervalSince(lastTime) < Self.doubleSpaceWindow {
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
            priorToModal = currentLayer
            currentLayer = .numeric

        case .diacritic:
            priorToModal = currentLayer
            currentLayer = .diacritic

        case .abc:
            // ع on the Latin layer always returns to Arabic letters. priorToModal
            // becomes .latin whenever 123/diacritics are opened from Latin (e.g.
            // Latin → 123 → ABC lands back in Latin). Without this special case the
            // line below would set currentLayer = priorToModal = .latin, so the ع
            // key would no-op and leave the keyboard stuck in English.
            if currentLayer == .latin {
                currentLayer = .default
            } else if priorToModal != .numeric && priorToModal != .diacritic {
                currentLayer = priorToModal
            } else {
                currentLayer = .default
            }

        case .latin:
            currentLayer = .latin
            if !KeyboardSettings.latinKeyTooltipShown {
                KeyboardSettings.latinKeyTooltipShown = true
                predictiveBar.showBriefMessage("Hold  AaBb  to switch keyboard", duration: 3.5)
            }

        case .shift:
            let now = Date()
            if let last = lastShiftTime, now.timeIntervalSince(last) < 0.35 {
                latinCapsLock = !latinCapsLock
                latinShifted  = latinCapsLock
            } else {
                if !latinCapsLock { latinShifted = !latinShifted }
            }
            lastShiftTime = now
            applyLayer()

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
        guard KeyboardSettings.doubleTapEnabled else {
            insert(key.primary)
            return
        }
        deleteBack()
        let secondary = (key.primary == "ا" && key.secondary == "اٰ" && KeyboardSettings.doubleAlefStyle == .alefMadda)
            ? "آ"
            : key.secondary
        insert(secondary)
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
        CorpusLogger.shared.resetPending()
        updatePredictions()
        updateBiDi()
    }

    func keyTapped(_ key: KeyData, touchOffset: CGPoint) {
        CorpusLogger.shared.recordTouchOffset(
            for: key.primary,
            dx:  Float(touchOffset.x),
            dy:  Float(touchOffset.y)
        )
    }
}

// MARK: - PredictiveBarDelegate

extension KeyboardViewController: PredictiveBarDelegate {
    func predictiveBar(_ bar: PredictiveBar, didSelect suggestion: String) {
        if jeemRevertPending {
            jeemRevertPending = false
            textDocumentProxy.deleteBackward() // space after ۚ
            textDocumentProxy.deleteBackward() // ۚ itself
            insert("ج ")
            return
        }
        let before  = textDocumentProxy.documentContextBeforeInput ?? ""
        let partial = before.components(separatedBy: .whitespaces).last ?? ""
        for _ in partial { textDocumentProxy.deleteBackward() }
        insert(suggestion + " ")
    }

    func predictiveBarDidTapSettings(_ bar: PredictiveBar) {
        let menu = KeyboardMenuView.show(in: view)
        let prevLayout = KeyboardSettings.selectedLayout
        menu.onDismiss = { [weak self] in
            if KeyboardSettings.selectedLayout != prevLayout {
                self?.currentLayer = .default
            }
            self?.applyLayer()
        }
    }

    func predictiveBarDidTapBiDi(_ bar: PredictiveBar, issue: BiDiAnalyzer.Issue) {
        showBiDiMenu(issue: issue)
    }
}
