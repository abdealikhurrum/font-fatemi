import Foundation
import InputMethodKit
import CoreGraphics
import os.log

// MARK: - LSDInputController
//
// Double-press strategy (physical keyboard, no touch):
//
//   1. Key with a secondary is pressed → set marked text (underlined composition).
//      The character appears immediately but isn't committed yet.
//   2. Same key pressed again within 0.35 s → commit the secondary, cancel timer.
//   3. Timer fires (0.35 s) → commit the primary.
//   4. A different key is pressed before the timer → commit the primary first,
//      then process the new key.
//
// Keys without secondaries are committed immediately (no delay, no marking).
//
// Caps Lock — diacritic mode:
//   Letter keys → diacritics (symmetric across both keyboard halves).
//   Z/X/C/V and mirror keys → cursor movement.
//   Number row 1–7 → BiDi control characters (LRM RLM LRI RLI PDI ZWJ ZWNJ).
//
// Subtending mark composition (Option layer, independent of Caps Lock):
//   Option+L → begin Sanah (U+0601, Arabic year sign) composition.
//   Option+P → begin Safha (U+0603, Arabic page sign) composition.
//   After the trigger, digit keys (Arabic-Indic) accumulate in marked text.
//   Return/Space commits mark + digits; Escape cancels; Backspace erases last digit.

@objc(LSDInputController)
final class LSDInputController: IMKInputController {

    private var doublePressWindow: TimeInterval { KeyboardSettings.doublePressDelay }

    private var pendingPrimary: String?
    private var pendingTimer: Timer?
    private var isDiacriticMode = false

    private var pendingSubtendingMark: String?
    private var subtendingDigits = ""

    private let log = Logger(subsystem: "com.exordiumnetworks.inputmethod.lsdkeyboard", category: "IME")

    // MARK: - Key event handling

    override func recognizedEvents(_ sender: Any!) -> Int {
        let events: NSEvent.EventTypeMask = [.keyDown, .flagsChanged]
        return Int(events.rawValue)
    }

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event else { return false }

        // Caps Lock toggle → diacritic mode + overlay
        if event.type == .flagsChanged && event.keyCode == 57 {
            isDiacriticMode = event.modifierFlags.contains(.capsLock)
            log.info("capsLock \(self.isDiacriticMode ? "ON→diacriticMode" : "OFF→normalMode", privacy: .public)")
            if isDiacriticMode {
                DiacriticOverlayPanel.shared.showOverlay()
            } else {
                DiacriticOverlayPanel.shared.hideOverlay()
            }
            return true
        }

        guard event.type == .keyDown else { return false }

        let mods = event.modifierFlags
        if mods.contains(.command) || mods.contains(.control) {
            commitPending()
            commitSubtending()
            return false
        }

        if pendingSubtendingMark != nil {
            return handleSubtendingKey(event)
        }

        return processKey(event)
    }

    // Handles all keyDown events when not in subtending mode.
    private func processKey(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags

        switch event.keyCode {
        case 51:        // Delete / Backspace
            CorpusLogger.shared.recordBackspace()
            cancelPending()
            return false
        case 36, 76:    // Return / Enter
            commitPending()
            return false
        case 48:        // Tab
            commitPending()
            return false
        case 53:        // Escape
            cancelPending()
            return false
        default:
            break
        }

        if isDiacriticMode && !mods.contains(.shift) && !mods.contains(.option) {
            let code = Int(event.keyCode)
            if let selector = KeyData.diacriticArrow(forCode: code) {
                commitPending()
                sendArrow(selector)
                return true
            }
            if let char = KeyData.diacriticChar(forCode: code) {
                commitPending()
                insert(char)
                return true
            }
            // unmapped key in diacritic mode — pass through
            return false
        }

        let isShift  = mods.contains(.shift)
        let isOption = mods.contains(.option)

        if isOption, !isShift,
           let mark = KeyData.optionSubtending(forCode: Int(event.keyCode)) {
            commitPending()
            startSubtending(mark: mark)
            return true
        }

        guard let chars = KeyData.char(forCode: Int(event.keyCode),
                                       shift: isShift, option: isOption) else {
            log.info("no-map code=\(event.keyCode, privacy: .public) shift=\(isShift, privacy: .public) opt=\(isOption, privacy: .public)")
            commitPending()
            return false
        }

        log.info("mapped code=\(event.keyCode, privacy: .public) shift=\(isShift, privacy: .public) opt=\(isOption, privacy: .public) → \"\(chars, privacy: .public)\"")

        if let pending = pendingPrimary, chars == pending,
           let secondary = KeyData.secondary(for: chars) {
            cancelTimer()
            pendingPrimary = nil
            log.info("double-press \(chars, privacy: .public) → \(secondary, privacy: .public)")
            insert(secondary)
            PairCollector.shared.recordDoublePress(primary: chars, secondary: secondary)
            return true
        }

        commitPending()

        if KeyData.secondary(for: chars) != nil {
            startComposition(char: chars)
        } else {
            insert(chars)
        }

        return true
    }

    // Handles keyDown events while a subtending mark is being composed.
    private func handleSubtendingKey(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 51:        // Backspace — erase last digit or cancel
            if subtendingDigits.isEmpty {
                cancelSubtending()
            } else {
                subtendingDigits = String(subtendingDigits.dropLast())
                updateSubtendingMarkedText()
            }
            return true
        case 36, 76:    // Return / Enter — commit, pass key to app
            commitSubtending()
            return false
        case 48:        // Tab — commit, pass key to app
            commitSubtending()
            return false
        case 53:        // Escape — cancel
            cancelSubtending()
            return true
        default:
            break
        }

        if let digit = subtendingDigit(from: event) {
            subtendingDigits += digit
            updateSubtendingMarkedText()
            return true
        }

        // Non-digit: commit composition then process the key normally.
        commitSubtending()
        return processKey(event)
    }

    // Returns an Arabic-Indic digit string if the event maps to a digit key,
    // nil otherwise.  Always produces Arabic-Indic so the composed text is
    // consistent with the rest of the LSD output.
    private func subtendingDigit(from event: NSEvent) -> String? {
        let arabicDigits: [Int: String] = [
            18: "١", 19: "٢", 20: "٣", 21: "٤", 23: "٥",
            22: "٦", 26: "٧", 28: "٨", 25: "٩", 29: "٠",
        ]
        return arabicDigits[Int(event.keyCode)]
    }

    // Called by the system when it needs the IME to finalize any open composition
    // (e.g., the user clicked elsewhere, the app requested it).
    override func commitComposition(_ sender: Any!) {
        commitPending()
        commitSubtending()
    }

    override func activateServer(_ sender: Any!) {
        isDiacriticMode = NSEvent.modifierFlags.contains(.capsLock)
        if isDiacriticMode {
            DiacriticOverlayPanel.shared.showOverlay()
        } else {
            DiacriticOverlayPanel.shared.hideOverlay()
        }
    }

    override func deactivateServer(_ sender: Any!) {
        log.info("deactivateServer — flushing corpus")
        CorpusLogger.shared.flush()
        commitPending()
        commitSubtending()
        DiacriticOverlayPanel.shared.hideOverlay()
    }

    deinit {
        cancelTimer()
    }

    // MARK: - Double-press composition lifecycle

    private func startComposition(char: String) {
        pendingPrimary = char
        log.info("startComposition \"\(char, privacy: .public)\"")

        activeClient?.setMarkedText(
            NSAttributedString(string: char),
            selectionRange: NSRange(location: char.utf16.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )

        pendingTimer = Timer.scheduledTimer(
            withTimeInterval: doublePressWindow,
            repeats: false
        ) { [weak self] _ in
            self?.commitPending()
        }
    }

    private func commitPending() {
        guard let char = pendingPrimary else { return }
        cancelTimer()
        pendingPrimary = nil
        log.info("commitPending \"\(char, privacy: .public)\"")
        insert(char)
    }

    private func cancelPending() {
        guard let char = pendingPrimary else { return }
        cancelTimer()
        pendingPrimary = nil
        log.info("cancelPending \"\(char, privacy: .public)\"")
        activeClient?.setMarkedText(
            NSAttributedString(string: ""),
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func cancelTimer() {
        pendingTimer?.invalidate()
        pendingTimer = nil
    }

    // MARK: - Subtending mark composition lifecycle

    private func startSubtending(mark: String) {
        pendingSubtendingMark = mark
        subtendingDigits = ""
        log.info("startSubtending \"\(mark, privacy: .public)\"")
        updateSubtendingMarkedText()
    }

    private func updateSubtendingMarkedText() {
        guard let mark = pendingSubtendingMark else { return }
        let composed = mark + subtendingDigits
        activeClient?.setMarkedText(
            NSAttributedString(string: composed),
            selectionRange: NSRange(location: composed.utf16.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func commitSubtending() {
        guard let mark = pendingSubtendingMark else { return }
        let text = mark + subtendingDigits
        pendingSubtendingMark = nil
        subtendingDigits = ""
        log.info("commitSubtending \"\(text, privacy: .public)\"")
        insert(text)
    }

    private func cancelSubtending() {
        guard pendingSubtendingMark != nil else { return }
        pendingSubtendingMark = nil
        subtendingDigits = ""
        log.info("cancelSubtending")
        activeClient?.setMarkedText(
            NSAttributedString(string: ""),
            selectionRange: NSRange(location: 0, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    // MARK: - Text insertion

    // Always use self.client() — the live accessor that IMKInputController
    // maintains per connection — rather than casting the `sender` parameter,
    // which can be a stale XPC proxy after a connection invalidation.
    private var activeClient: (IMKTextInput & NSObjectProtocol)? { self.client() }

    private func insert(_ text: String) {
        log.info("insert \(text, privacy: .public) hasClient=\(self.activeClient != nil, privacy: .public)")
        CorpusLogger.shared.record(text)
        self.activeClient?.insertText(
            text,
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    // Synthesises an arrow-key CGEvent and posts it to the session so the
    // focused app's text view moves the cursor.  Using CGEvent instead of
    // perform(selector:) on the IMK proxy because the proxy does not forward
    // arbitrary NSResponder selectors cross-process on modern macOS.
    private func sendArrow(_ selector: String) {
        let vk: CGKeyCode
        switch selector {
        case "moveLeft:":  vk = 0x7B
        case "moveRight:": vk = 0x7C
        case "moveDown:":  vk = 0x7D
        case "moveUp:":    vk = 0x7E
        default: return
        }
        let src = CGEventSource(stateID: .combinedSessionState)
        if let dn = CGEvent(keyboardEventSource: src, virtualKey: vk, keyDown: true) {
            dn.post(tap: .cgAnnotatedSessionEventTap)
        }
        if let up = CGEvent(keyboardEventSource: src, virtualKey: vk, keyDown: false) {
            up.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    // MARK: - Mode switching
    //
    // Called by the system when the user switches between registered input modes
    // (LSDWindows / LSDMac / CRULP). Syncs the TIS mode into KeyboardSettings so
    // KeyData picks up the right layout layers immediately.

    override func setValue(_ value: Any!, forTag tag: Int, client sender: Any!) {
        if let modeID = value as? String {
            switch modeID {
            case _ where modeID.hasSuffix(".LSDWindows"):
                KeyboardSettings.selectedLayout = .lsd
            case _ where modeID.hasSuffix(".LSDMac"):
                KeyboardSettings.selectedLayout = .macLsd
            case _ where modeID.hasSuffix(".CRULP"):
                KeyboardSettings.selectedLayout = .crulpUrdu
            default:
                break
            }
            log.info("mode → \(modeID, privacy: .public) layout=\(KeyboardSettings.selectedLayout.rawValue, privacy: .public)")
        }
        super.setValue(value, forTag: tag, client: sender)
    }

    // MARK: - Settings menu
    //
    // Appears when the user clicks the input source name in the menu bar.
    // Layout switching is handled by the system (TIS modes in Info.plist);
    // this menu covers per-mode behaviour settings only.

    override func menu() -> NSMenu! {
        let menu = NSMenu(title: "Lisan ud Dawat")

        let header = NSMenuItem(title: "Lisan ud Dawat", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // Double-press enabled
        let dpItem = NSMenuItem(title: "Double-press", action: #selector(toggleDoublePress(_:)),
                                keyEquivalent: "")
        dpItem.state  = KeyboardSettings.doublePressEnabled ? .on : .off
        dpItem.target = self
        menu.addItem(dpItem)

        // Double-press delay
        let delayItem = NSMenuItem(title: "Double-press delay", action: nil, keyEquivalent: "")
        let delayMenu = NSMenu()
        for (index, preset) in KeyboardSettings.DelayPreset.allCases.enumerated() {
            let item = NSMenuItem(title: preset.label, action: #selector(setDelay(_:)),
                                  keyEquivalent: "")
            item.tag    = index
            item.state  = KeyboardSettings.doublePressDelayPreset == preset ? .on : .off
            item.target = self
            delayMenu.addItem(item)
        }
        delayItem.submenu = delayMenu
        menu.addItem(delayItem)

        menu.addItem(.separator())

        // Double alef style
        let alefItem = NSMenuItem(title: "Double alef (اا)", action: nil, keyEquivalent: "")
        let alefMenu = NSMenu()
        let alefOptions: [(KeyboardSettings.DoubleAlefStyle, String)] = [
            (.kharoZabar, "اٰ  kharo zabar (default)"),
            (.alefMadda,  "آ  alef madda"),
        ]
        for (index, (style, label)) in alefOptions.enumerated() {
            let item = NSMenuItem(title: label, action: #selector(setDoubleAlef(_:)),
                                  keyEquivalent: "")
            item.tag    = index
            item.state  = KeyboardSettings.doubleAlefStyle == style ? .on : .off
            item.target = self
            alefMenu.addItem(item)
        }
        alefItem.submenu = alefMenu
        menu.addItem(alefItem)

        // Urdu yeh style
        let yehItem = NSMenuItem(title: "Urdu yeh  (CRULP)", action: nil, keyEquivalent: "")
        let yehMenu = NSMenu()
        let yehOptions: [(KeyboardSettings.UrduYehStyle, String)] = [
            (.farsiYeh,  "ی  Farsi yeh  (default)"),
            (.arabicYeh, "ي  Arabic yeh"),
        ]
        for (index, (style, label)) in yehOptions.enumerated() {
            let item = NSMenuItem(title: label, action: #selector(setUrduYeh(_:)),
                                  keyEquivalent: "")
            item.tag    = index
            item.state  = KeyboardSettings.urduYehStyle == style ? .on : .off
            item.target = self
            yehMenu.addItem(item)
        }
        yehItem.submenu = yehMenu
        menu.addItem(yehItem)

        return menu
    }

    @objc private func toggleDoublePress(_ sender: NSMenuItem) {
        KeyboardSettings.doublePressEnabled.toggle()
        cancelPending()
    }

    @objc private func setDelay(_ sender: NSMenuItem) {
        let presets = KeyboardSettings.DelayPreset.allCases
        guard sender.tag < presets.count else { return }
        KeyboardSettings.doublePressDelayPreset = presets[sender.tag]
    }

    @objc private func setDoubleAlef(_ sender: NSMenuItem) {
        let options: [KeyboardSettings.DoubleAlefStyle] = [.kharoZabar, .alefMadda]
        guard sender.tag < options.count else { return }
        KeyboardSettings.doubleAlefStyle = options[sender.tag]
    }

    @objc private func setUrduYeh(_ sender: NSMenuItem) {
        let options: [KeyboardSettings.UrduYehStyle] = [.farsiYeh, .arabicYeh]
        guard sender.tag < options.count else { return }
        KeyboardSettings.urduYehStyle = options[sender.tag]
    }
}
