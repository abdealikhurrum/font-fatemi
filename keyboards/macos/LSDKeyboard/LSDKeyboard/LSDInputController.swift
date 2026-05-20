import Foundation
import InputMethodKit

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

    private static let doublePressWindow: TimeInterval = 0.35

    // Character currently held in marked-text composition, if any.
    private var pendingPrimary: String?
    private var pendingTimer: Timer?

    // MARK: - Key event handling

    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let event, event.type == .keyDown else { return false }

        let mods = event.modifierFlags.intersection([.command, .option, .control])
        guard mods.isEmpty else {
            // Modified key: commit composition and let the app handle it.
            commitPending()
            return false
        }

        switch event.keyCode {
        case 51:        // Delete / Backspace
            CorpusLogger.shared.recordBackspace()
            cancelPending()             // discard composition, don't commit
            return false                // let the app handle the delete
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

        guard let chars = event.characters, !chars.isEmpty else {
            commitPending()
            return false
        }

        // Double-press: same char arrives while it's still in composition.
        if let pending = pendingPrimary, chars == pending,
           let secondary = KeyData.secondary(for: chars) {
            cancelTimer()
            pendingPrimary = nil
            insert(secondary, into: sender)
            PairCollector.shared.recordDoublePress(primary: chars, secondary: secondary)
            return true
        }

        // Commit any existing composition before handling this new character.
        commitPending()

        if KeyData.secondary(for: chars) != nil {
            // Hold in composition so a quick second press can substitute.
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

    // Called when this input method is deactivated (user switched away).
    override func deactivateServer(_ sender: Any!) {
        CorpusLogger.shared.flush()
        commitPending()
    }

    // MARK: - Composition lifecycle

    private func startComposition(char: String, sender: Any?) {
        pendingPrimary = char

        let client = textClient(sender)
        client?.setMarkedText(
            NSAttributedString(string: char),
            selectionRange: NSRange(location: char.utf16.count, length: 0),
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )

        pendingTimer = Timer.scheduledTimer(
            withTimeInterval: Self.doublePressWindow,
            repeats: false
        ) { [weak self] _ in
            self?.commitPending()
        }
    }

    private func commitPending() {
        guard let char = pendingPrimary else { return }
        cancelTimer()
        pendingPrimary = nil
        insert(char, into: client())
    }

    // Discard the pending composition without inserting anything.
    private func cancelPending() {
        guard pendingPrimary != nil else { return }
        cancelTimer()
        pendingPrimary = nil
        // Clear the marked text so the underline disappears.
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
        CorpusLogger.shared.record(text)
        textClient(sender)?.insertText(
            text,
            replacementRange: NSRange(location: NSNotFound, length: NSNotFound)
        )
    }

    private func textClient(_ sender: Any?) -> (IMKTextInput & NSObjectProtocol)? {
        sender as? (IMKTextInput & NSObjectProtocol)
    }
}
