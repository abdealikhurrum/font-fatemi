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

final class LSDInputController: IMKInputController {

    private var doublePressWindow: TimeInterval { KeyboardSettings.doublePressDelay }

    private var pendingPrimary: String?
    private var pendingTimer: Timer?

    #if DEBUG
    private let log = Logger(subsystem: "com.exordiumnetworks.lsdkeyboard.macos", category: "IME")
    #endif

    // MARK: - Key event handling

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, event.type == .keyDown else { return false }

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

        let isShift  = mods.contains(.shift)
        let isOption = mods.contains(.option)
        guard let chars = KeyData.char(forCode: Int(event.keyCode),
                                       shift: isShift, option: isOption) else {
            commitPending()
            return false
        }

        #if DEBUG
        log.debug("key=\(event.keyCode) shift=\(isShift) opt=\(isOption) → \"\(chars)\"")
        #endif

        if let pending = pendingPrimary, chars == pending,
           let secondary = KeyData.secondary(for: chars) {
            cancelTimer()
            pendingPrimary = nil
            #if DEBUG
            log.debug("double-press \"\(chars)\" → \"\(secondary)\"")
            #endif
            insert(secondary, into: sender)
            PairCollector.shared.recordDoublePress(primary: chars, secondary: secondary)
            return true
        }

        commitPending()

        if KeyData.secondary(for: chars) != nil {
            startComposition(char: chars, sender: sender)
        } else {
            insert(chars, into: sender)
        }

        return true
    }

    // Called by the system when it needs the IME to finalize any open composition
    // (e.g., the user clicked elsewhere, the app requested it).
    override func commitComposition(_ sender: Any!) {
        commitPending()
    }

    override func deactivateServer(_ sender: Any!) {
        #if DEBUG
        log.debug("deactivateServer — flushing corpus")
        #endif
        CorpusLogger.shared.flush()
        commitPending()
    }

    // MARK: - Composition lifecycle

    private func startComposition(char: String, sender: Any?) {
        pendingPrimary = char
        #if DEBUG
        log.debug("startComposition \"\(char)\"")
        #endif

        let client = textClient(sender)
        client?.setMarkedText(
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
        #if DEBUG
        log.debug("commitPending \"\(char)\"")
        #endif
        insert(char, into: client())
    }

    private func cancelPending() {
        guard let char = pendingPrimary else { return }
        cancelTimer()
        pendingPrimary = nil
        #if DEBUG
        log.debug("cancelPending \"\(char)\"")
        #endif
        textClient(client())?.setMarkedText(
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

    private func insert(_ text: String, into sender: Any?) {
        #if DEBUG
        log.debug("insert \"\(text)\"")
        #endif
        CorpusLogger.shared.record(text)
        textClient(sender)?.insertText(
            text,
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func textClient(_ sender: Any?) -> (IMKTextInput & NSObjectProtocol)? {
        sender as? (IMKTextInput & NSObjectProtocol)
    }

    // MARK: - Settings menu
    //
    // Appears when the user clicks "Lisan ud Dawat" in the Input Sources menu bar item.

    override func menu() -> NSMenu! {
        let menu = NSMenu(title: "Lisan ud Dawat")

        let header = NSMenuItem(title: "Lisan ud Dawat", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // Layout
        let layoutItem = NSMenuItem(title: "Layout", action: nil, keyEquivalent: "")
        let layoutMenu = NSMenu()
        for layout in KeyboardSettings.LayoutType.allCases {
            let item = NSMenuItem(title: layout.label, action: #selector(setLayout(_:)),
                                  keyEquivalent: "")
            item.representedObject = layout.rawValue
            item.state = KeyboardSettings.selectedLayout == layout ? .on : .off
            item.target = self
            layoutMenu.addItem(item)
        }
        layoutItem.submenu = layoutMenu
        menu.addItem(layoutItem)

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

    @objc private func setLayout(_ sender: NSMenuItem) {
        guard let raw    = sender.representedObject as? String,
              let layout = KeyboardSettings.LayoutType(rawValue: raw) else { return }
        KeyboardSettings.selectedLayout = layout
    }

    @objc private func toggleDoublePress(_ sender: NSMenuItem) {
        KeyboardSettings.doublePressEnabled.toggle()
        // Discard any pending composition so the new state takes effect immediately.
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
