import AppKit

/// The one place this app uses Accessibility: a window's AXFullScreen attribute is the
/// only full-screen switch reachable from outside its app.
enum FullScreen {
    /// `prompt` raises the system dialog pointing at Privacy › Accessibility; there is
    /// no Allow button for this grant, the user has to flip it there.
    static func trusted(prompt: Bool) -> Bool {
        AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary)
    }

    /// Returns the window so `exit` can find it again once its bounds have changed.
    /// `bounds` is CGWindowList's top-left space, which is also what AX reports.
    static func enter(pid: pid_t, bounds: CGRect) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        // The default is six seconds per call, on the main thread, if the app is hung.
        AXUIElementSetMessagingTimeout(app, 1)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &value) == .success,
              let windows = value as? [AXUIElement],
              let window = windows.first(where: { frame($0) == bounds }),
              set(window, true) else { return nil }
        return window
    }

    static func exit(_ window: AXUIElement) { _ = set(window, false) }

    private static func set(_ window: AXUIElement, _ on: Bool) -> Bool {
        AXUIElementSetAttributeValue(window, "AXFullScreen" as CFString,
                                     on ? kCFBooleanTrue : kCFBooleanFalse) == .success
    }

    static func frame(_ window: AXUIElement) -> CGRect? {
        var position: CFTypeRef?, size: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size) == .success
        else { return nil }
        var origin = CGPoint.zero, extent = CGSize.zero
        AXValueGetValue(position as! AXValue, .cgPoint, &origin)
        AXValueGetValue(size as! AXValue, .cgSize, &extent)
        return CGRect(origin: origin, size: extent)
    }
}
