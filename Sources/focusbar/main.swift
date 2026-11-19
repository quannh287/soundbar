import AppKit
import FocusKit

if CommandLine.arguments.contains("--list") {
    MainActor.assumeIsolated { selfCheck() }
    exit(0)
}

let app = NSApplication.shared
// Held by a top-level binding so it outlives this scope; NSApplication keeps only a weak delegate.
let delegate = MainActor.assumeIsolated { AppDelegate() }
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
