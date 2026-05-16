import UIKit

// UIInputViewController subclass — the entry point for the iOS keyboard extension.
// Manages layer switching, text insertion, and the keyboard view hierarchy.

final class KeyboardViewController: UIInputViewController {

    // MARK: - Layer State

    private enum Layer { case `default`, shift, numeric }

    private var currentLayer: Layer = .default {
        didSet { applyLayer() }
    }

    private var shiftLocked = false  // double-tap shift activates caps lock

    // MARK: - Views

    private var keyboardView: KeyboardView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        buildKeyboardView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Force layout pass so intrinsic content size is respected
        view.setNeedsLayout()
    }

    // MARK: - Setup

    private func buildKeyboardView() {
        keyboardView = KeyboardView()
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        keyboardView.delegate = self
        view.addSubview(keyboardView)

        NSLayoutConstraint.activate([
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        applyLayer()
    }

    private func applyLayer() {
        switch currentLayer {
        case .default:  keyboardView.configure(with: KeyboardLayoutData.defaultLayer)
        case .shift:    keyboardView.configure(with: KeyboardLayoutData.shiftLayer)
        case .numeric:  keyboardView.configure(with: KeyboardLayoutData.numericLayer)
        }
    }

    // MARK: - Text Helpers

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    private func deleteBack() {
        textDocumentProxy.deleteBackward()
    }
}

// MARK: - KeyboardViewDelegate

extension KeyboardViewController: KeyboardViewDelegate {

    func keyPressed(_ key: KeyData) {
        switch key.type {

        case .character:
            insert(key.primary)
            // Single-shot shift returns to default
            if currentLayer == .shift, !shiftLocked {
                currentLayer = .default
            }

        case .space:
            insert(" ")

        case .backspace:
            deleteBack()

        case .enter:
            insert("\n")

        case .shift:
            switch currentLayer {
            case .default:
                currentLayer = .shift
                shiftLocked = false
            case .shift where !shiftLocked:
                // Second tap on shift = caps lock
                shiftLocked = true
            case .shift where shiftLocked:
                // Third tap = release caps lock
                shiftLocked = false
                currentLayer = .default
            case .numeric:
                break   // shift does nothing in numeric layer
            default:
                break
            }

        case .numeric:
            currentLayer = .numeric

        case .abc:
            currentLayer = .default

        case .globe:
            advanceToNextInputMode()
        }
    }

    func longPressAlternateSelected(_ character: String) {
        insert(character)
        if currentLayer == .shift, !shiftLocked {
            currentLayer = .default
        }
    }
}
