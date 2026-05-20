import Foundation
import InputMethodKit

// IMKServer must be created before NSApp.run() so the Input Method Manager
// registers the connection name before any client attempts to connect.
let info = Bundle.main.infoDictionary!
let connectionName = info["InputMethodConnectionName"] as! String
let bundleIdentifier = Bundle.main.bundleIdentifier!
let server = IMKServer(name: connectionName, bundleIdentifier: bundleIdentifier)
NSApplication.shared.run()
