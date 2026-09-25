import Cocoa

// Host app for the Finder Sync extension. It has no UI: launching it once
// registers the extension, then it opens the Finder extensions settings pane.
NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
