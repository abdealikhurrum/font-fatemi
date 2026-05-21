import Foundation
import InputMethodKit
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

@objc(LSDInputController)
final class LSDInputController: IMKInputController {

    private var doublePressWindow: TimeInterval { KeyboardSettings.doublePressDelay }

    private var pendingPrimary: String?
    private var pendingTimer: Timer?
    private var isDiacriticMode = false

    private let log = Logger(subsystem: "com.exordiumnetworks.inputmethod.lsdkeyboard", category: "IME")

    // MARK: - Key event handling

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event else { return false }

        // Handle Caps Lock toggle → diacritic mode
        if event.type == .flagsChanged && event.keyCode == 57 {
            isDiacriticMode = event.modifierFlags.contains(.capsLock)
            log.info("capsLock \(self.isDiacriticMode ? "ON→diacriticMode" : "OFF→normalMode", privacy: .public)")
            return true
        }

        guard event.type == .keyDown else { return false }

        let mods = event.modifierFlags
        if mods.contains(.command) || mods.contains(.control) {
            commitPending()
            return false
        }

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
                NSApp.sendAction(NSSelectorFromString(selector), to: nil, from: self)
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

    // Called by the system when it needs the IME to finalize any open composition
    // (e.g., the user clicked elsewhere, the app requested it).
    override func commitComposition(_ sender: Any!) {
        commitPending()
    }

    override func deactivateServer(_ sender: Any!) {
        log.info("deactivateServer — flushing corpus")
        CorpusLogger.shared.flush()
        commitPending()
    }

    // MARK: - Composition lifecycle

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
        for preset in KeyboardSettings.DelayPreset.allCases {
            let item = NSMenuItem(title: preset.label, action: #selector(setDelay(_:)),
                                  keyEquivalent: "")
            item.representedObject = preset.rawValue
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
        for (style, label) in alefOptions {
            let item = NSMenuItem(title: label, action: #selector(setDoubleAlef(_:)),
                                  keyEquivalent: "")
            item.representedObject = style.rawValue
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
        for (style, label) in yehOptions {
            let item = NSMenuItem(title: label, action: #selector(setUrduYeh(_:)),
                                  keyEquivalent: "")
            item.representedObject = style.rawValue
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
        guard let raw    = sender.representedObject as? String,
              let preset = KeyboardSettings.DelayPreset(rawValue: raw) else { return }
        KeyboardSettings.doublePressDelayPreset = preset
    }

    @objc private func setDoubleAlef(_ sender: NSMenuItem) {
        guard let raw   = sender.representedObject as? String,
              let style = KeyboardSettings.DoubleAlefStyle(rawValue: raw) else { return }
        KeyboardSettings.doubleAlefStyle = style
    }

    @objc private func setUrduYeh(_ sender: NSMenuItem) {
        guard let raw   = sender.representedObject as? String,
              let style = KeyboardSettings.UrduYehStyle(rawValue: raw) else { return }
        KeyboardSettings.urduYehStyle = style
    }
}
