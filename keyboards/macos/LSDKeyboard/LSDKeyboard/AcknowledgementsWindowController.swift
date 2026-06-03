import Cocoa

// MARK: - AcknowledgementsWindowController
//
// Process-lifetime singleton that owns the acknowledgements window, mirroring
// PreferencesWindowController. Shows the licenses of the third-party code this
// input method depends on (IMKSwift) and credits the FatemiMaqala companion
// font, whose MIT license asks that its copyright notice travel with it.

final class AcknowledgementsWindowController: NSObject, NSWindowDelegate {
    static let shared = AcknowledgementsWindowController()
    private override init() {}

    private var window: NSWindow?

    func showWindow() {
        if window == nil { window = makeWindow() }
        window?.level = .floating
        window?.center()
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Window construction

    private func makeWindow() -> NSWindow {
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 460),
            styleMask:   [.titled, .closable, .resizable],
            backing:     .buffered,
            defer:       false
        )
        w.title                = "Acknowledgements"
        w.isReleasedWhenClosed = false
        w.delegate             = self

        let textView = NSTextView()
        textView.isEditable        = false
        textView.isSelectable       = true
        textView.drawsBackground    = true
        textView.backgroundColor    = .textBackgroundColor
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.font               = .monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.string             = Self.creditsText

        let scroll = NSScrollView()
        scroll.documentView         = textView
        scroll.hasVerticalScroller  = true
        scroll.autohidesScrollers   = true
        scroll.borderType           = .noBorder

        w.contentView = scroll
        return w
    }

    // MARK: - Content

    private static let creditsText: String = {
        let mit = { (holder: String) in
            """
            MIT License

            Copyright (c) 2026 \(holder)

            Permission is hereby granted, free of charge, to any person obtaining a
            copy of this software and associated documentation files (the "Software"),
            to deal in the Software without restriction, including without limitation
            the rights to use, copy, modify, merge, publish, distribute, sublicense,
            and/or sell copies of the Software, and to permit persons to whom the
            Software is furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in
            all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
            FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
            IN THE SOFTWARE.
            """
        }

        return """
        Lisan ud Dawat Keyboard (LSDKeyboard)
        Distributed under the MIT License.

        \(mit("Abdeali Khurrum"))

        ────────────────────────────────────────────────────────────────────────

        IMKSwift
        Swift helpers for Input Method Kit.
        https://github.com/vChewing/IMKSwift

        \(mit("ShikiSuen"))

        ────────────────────────────────────────────────────────────────────────

        FatemiMaqala (companion font)
        The Lisan ud Dawat typeface this keyboard is designed for. It is not
        bundled with the keyboard — install it separately so apps render text
        correctly. Distributed under the MIT License.

        \(mit("Abdeali Khurrum"))
        """
    }()
}
