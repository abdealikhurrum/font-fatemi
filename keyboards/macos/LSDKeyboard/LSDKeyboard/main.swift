import Foundation
import InputMethodKit

// IMKServer must be created before NSApp.run() so the Input Method Manager
// registers the connection name before any client attempts to connect.
let connectionName = Bundle.main.infoDictionary?["InputMethodConnectionName"] as? String
    ?? "LSDKeyboard_Connection"

let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)
NSApplication.shared.run()
