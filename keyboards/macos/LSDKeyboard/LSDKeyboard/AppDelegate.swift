import Cocoa

// MARK: - AppDelegate
//
// Sets up the NSStatusItem that provides reliable in-process access to the
// preferences window. IMKit's menu() dispatch crosses a process boundary
// (TextInputMenuAgent) and is unreliable for custom targets; a status item
// in the same process has no such limitation.

@objc(AppDelegate)
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = item.button {
            btn.image = NSImage(systemSymbolName: "keyboard",
                                accessibilityDescription: "Lisan ud Dawat")
            btn.image?.isTemplate = true
            btn.toolTip = "Lisan ud Dawat"
        }

        let menu = NSMenu()
        let pref = NSMenuItem(title: "Preferences\u{2026}",
                              action: #selector(openPreferences(_:)),
                              keyEquivalent: "")
        pref.target = self
        menu.addItem(pref)
        item.menu = menu

        statusItem = item
    }

    @objc func openPreferences(_ sender: Any?) {
        PreferencesWindowController.shared.showWindow()
    }
}
