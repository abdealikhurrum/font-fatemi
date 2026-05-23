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
//
// Caps Lock — diacritic mode:
//   QWERTY row → primary harakat.  ASDF row → secondary/Quranic diacritics.
//   ZXCV row  → document/literary marks (takhallus, ayah, sanah, safha …).
//   Number row → Quranic pause/decoration marks (U+06D6–U+06E8).
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

        // Modifier changes — handle Caps Lock and Option
        if event.type == .flagsChanged {
            let flags = event.modifierFlags
            let capOn = flags.contains(.capsLock)
            let optOn = flags.contains(.option)

            if event.keyCode == 57 {            // Caps Lock key
                isDiacriticMode = capOn
                log.info("capsLock \(capOn ? "ON" : "OFF", privacy: .public)")
                if capOn {
                    DiacriticOverlayPanel.shared.showOverlay(optionMode: optOn)
                } else {
                    DiacriticOverlayPanel.shared.hideOverlay()
                }
                return true
            }

            if isDiacriticMode && (event.keyCode == 58 || event.keyCode == 61) {
                // Left or right Option pressed/released while in diacritic mode
                DiacriticOverlayPanel.shared.showOverlay(optionMode: optOn)
                return true
            }

            return false   // pass all other modifier events (Shift, Cmd, Ctrl…) to the app
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
            if let char = KeyData.diacriticChar(forCode: code) {
                commitPending()
                insert(char)
                return true
            }
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
    //
    // IMPORTANT: menu item targets must point to a persistent object.
    // LSDInputController instances are created/destroyed per text context, so
    // `target = self` causes submenu actions to be dropped if the instance that
    // built the menu has since been deallocated.  MenuActions.shared is a
    // process-lifetime singleton that is never deallocated.

    override func menu() -> NSMenu! {
        let t = MenuActions.shared

        let menu = NSMenu(title: "Lisan ud Dawat")

        let header = NSMenuItem(title: "Lisan ud Dawat", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // Double-press enabled toggle
        let dpItem = NSMenuItem(title: "Double-press", action: #selector(MenuActions.toggleDoublePress(_:)),
                                keyEquivalent: "")
        dpItem.state  = KeyboardSettings.doublePressEnabled ? .on : .off
        dpItem.target = t
        menu.addItem(dpItem)

        menu.addItem(.separator())

        // Double-press delay — flat items (submenus are unreliable in IMKit)
        let delayHeader = NSMenuItem(title: "Double-press delay", action: nil, keyEquivalent: "")
        delayHeader.isEnabled = false
        menu.addItem(delayHeader)
        for preset in KeyboardSettings.DelayPreset.allCases {
            let item = NSMenuItem(title: preset.label, action: #selector(MenuActions.setDelay(_:)),
                                  keyEquivalent: "")
            item.representedObject = preset.rawValue
            item.state             = KeyboardSettings.doublePressDelayPreset == preset ? .on : .off
            item.target            = t
            item.indentationLevel  = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Double alef style — flat items
        let alefHeader = NSMenuItem(title: "Double alef (\u{0627}\u{0627})", action: nil, keyEquivalent: "")
        alefHeader.isEnabled = false
        menu.addItem(alefHeader)
        let alefOptions: [(KeyboardSettings.DoubleAlefStyle, String)] = [
            (.kharoZabar, "\u{0627}\u{0670}  kharo zabar (default)"),
            (.alefMadda,  "\u{0622}  alef madda"),
        ]
        for (style, label) in alefOptions {
            let item = NSMenuItem(title: label, action: #selector(MenuActions.setDoubleAlef(_:)),
                                  keyEquivalent: "")
            item.representedObject = style.rawValue
            item.state             = KeyboardSettings.doubleAlefStyle == style ? .on : .off
            item.target            = t
            item.indentationLevel  = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Yeh style — flat items (applies to all layouts)
        let yehHeader = NSMenuItem(title: "Yeh", action: nil, keyEquivalent: "")
        yehHeader.isEnabled = false
        menu.addItem(yehHeader)
        let yehOptions: [(KeyboardSettings.UrduYehStyle, String)] = [
            (.farsiYeh,  "\u{06CC}  Farsi/Urdu yeh  (default)"),
            (.arabicYeh, "\u{064A}  Arabic yeh"),
        ]
        for (style, label) in yehOptions {
            let item = NSMenuItem(title: label, action: #selector(MenuActions.setUrduYeh(_:)),
                                  keyEquivalent: "")
            item.representedObject = style.rawValue
            item.state             = KeyboardSettings.urduYehStyle == style ? .on : .off
            item.target            = t
            item.indentationLevel  = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Kaaf style — flat items
        let kaafHeader = NSMenuItem(title: "Kaaf", action: nil, keyEquivalent: "")
        kaafHeader.isEnabled = false
        menu.addItem(kaafHeader)
        let kaafOptions: [(KeyboardSettings.UrduKaafStyle, String)] = [
            (.arabicKaaf, "\u{0643}  Arabic kaaf  (default)"),
            (.urduKaaf,   "\u{06A9}  Urdu kaaf"),
        ]
        for (style, label) in kaafOptions {
            let item = NSMenuItem(title: label, action: #selector(MenuActions.setUrduKaaf(_:)),
                                  keyEquivalent: "")
            item.representedObject = style.rawValue
            item.state             = KeyboardSettings.urduKaafStyle == style ? .on : .off
            item.target            = t
            item.indentationLevel  = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Haa style — flat items
        let haaHeader = NSMenuItem(title: "Haa", action: nil, keyEquivalent: "")
        haaHeader.isEnabled = false
        menu.addItem(haaHeader)
        let haaOptions: [(KeyboardSettings.UrduHaaStyle, String)] = [
            (.arabicHaa, "\u{0647}  Arabic haa  (default)"),
            (.heGoal,    "\u{06C1}  Urdu he goal"),
        ]
        for (style, label) in haaOptions {
            let item = NSMenuItem(title: label, action: #selector(MenuActions.setUrduHaa(_:)),
                                  keyEquivalent: "")
            item.representedObject = style.rawValue
            item.state             = KeyboardSettings.urduHaaStyle == style ? .on : .off
            item.target            = t
            item.indentationLevel  = 1
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // Taa marbuta style — flat items
        let taaHeader = NSMenuItem(title: "Taa marbuta", action: nil, keyEquivalent: "")
        taaHeader.isEnabled = false
        menu.addItem(taaHeader)
        let taaOptions: [(KeyboardSettings.UrduTaaMarbutaStyle, String)] = [
            (.arabicTaaMarbuta, "\u{0629}  Arabic taa marbuta  (default)"),
            (.urduTaaMarbuta,   "\u{06C3}  Urdu taa marbuta"),
        ]
        for (style, label) in taaOptions {
            let item = NSMenuItem(title: label, action: #selector(MenuActions.setUrduTaaMarbuta(_:)),
                                  keyEquivalent: "")
            item.representedObject = style.rawValue
            item.state             = KeyboardSettings.urduTaaMarbutaStyle == style ? .on : .off
            item.target            = t
            item.indentationLevel  = 1
            menu.addItem(item)
        }

        return menu
    }
}

// MARK: - MenuActions
//
// Process-lifetime singleton that receives settings menu actions.
// Must outlive any LSDInputController instance — stored as a static let.
final class MenuActions: NSObject {
    static let shared = MenuActions()
    private override init() {}

    @objc func toggleDoublePress(_ sender: NSMenuItem) {
        KeyboardSettings.doublePressEnabled.toggle()
    }

    @objc func setDelay(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let preset = KeyboardSettings.DelayPreset(rawValue: raw) else { return }
        KeyboardSettings.doublePressDelayPreset = preset
    }

    @objc func setDoubleAlef(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = KeyboardSettings.DoubleAlefStyle(rawValue: raw) else { return }
        KeyboardSettings.doubleAlefStyle = style
    }

    @objc func setUrduYeh(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = KeyboardSettings.UrduYehStyle(rawValue: raw) else { return }
        KeyboardSettings.urduYehStyle = style
    }

    @objc func setUrduKaaf(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = KeyboardSettings.UrduKaafStyle(rawValue: raw) else { return }
        KeyboardSettings.urduKaafStyle = style
    }

    @objc func setUrduHaa(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = KeyboardSettings.UrduHaaStyle(rawValue: raw) else { return }
        KeyboardSettings.urduHaaStyle = style
    }

    @objc func setUrduTaaMarbuta(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String,
              let style = KeyboardSettings.UrduTaaMarbutaStyle(rawValue: raw) else { return }
        KeyboardSettings.urduTaaMarbutaStyle = style
    }
}
