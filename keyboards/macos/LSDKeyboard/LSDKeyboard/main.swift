import Cocoa
import InputMethodKit

// Delegate must be set before run() so applicationDidFinishLaunching fires.
let appDelegate = AppDelegate()
NSApplication.shared.delegate = appDelegate

// IMKServer must be created before NSApp.run() so the Input Method Manager
// registers the connection name before any client attempts to connect.
let info           = Bundle.main.infoDictionary!
let connectionName = info["InputMethodConnectionName"] as! String
let bundleID       = Bundle.main.bundleIdentifier!
let server         = IMKServer(name: connectionName, bundleIdentifier: bundleID)

NSApplication.shared.run()
