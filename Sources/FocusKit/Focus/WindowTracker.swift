import AppKit

public struct WindowInfo: Equatable {
    public let id: CGWindowID
    public let pid: pid_t
    /// Top-left origin, global display space. Convert with `cocoaRect` before use in AppKit.
    public let bounds: CGRect
    /// nil unless the app happens to hold Screen Recording; never required, only nicer.
    public var title: String?

    public var label: String {
        let t = title?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !t.isEmpty else { return WindowTracker.appName(pid) }
        // A browser tab title is far wider than a 320pt popover; the tail is the part
        // that repeats across tabs anyway.
        return t.count <= 38 ? t : t.prefix(37) + "…"
    }
}

/// Everything here reads CGWindowList, which needs no TCC grant and shows no prompt.
/// Deliberately not AX: TCC binds that grant to the code signature, and an ad-hoc
/// signature changes on every build, so the grant would evaporate each time. Only the
/// opt-in full screen in `FullScreen` pays that price.
public enum WindowTracker {
    /// Below this a window is a tooltip, shadow or scratch panel, never a focus target.
    static let minSide: CGFloat = 120

    /// Front to back, which is what CGWindowList documents for any "OnScreen" option.
    public static func onScreen() -> [WindowInfo] {
        let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let raw = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] ?? []
        let me = ProcessInfo.processInfo.processIdentifier
        return raw.compactMap { entry -> WindowInfo? in
            guard entry[kCGWindowLayer as String] as? Int == 0,
                  (entry[kCGWindowAlpha as String] as? Double ?? 1) > 0,
                  let number = entry[kCGWindowNumber as String] as? CGWindowID,
                  let pid = entry[kCGWindowOwnerPID as String] as? pid_t, pid != me,
                  let dict = entry[kCGWindowBounds as String] as? [String: Any],
                  let bounds = CGRect(dictionaryRepresentation: dict as CFDictionary),
                  bounds.width >= minSide, bounds.height >= minSide,
                  // Drops the Window Server and background agents like storeuid, which have
                  // been seen registering layer-0 windows and stealing "frontmost".
                  regularName(pid) != nil
            else { return nil }
            return WindowInfo(id: number, pid: pid, bounds: bounds,
                              title: entry[kCGWindowName as String] as? String)
        }
    }

    public static func frontmost() -> WindowInfo? { onScreen().first }

    /// nil once the window is closed or minimised — CGWindowList cannot tell those apart.
    public static func bounds(of id: CGWindowID) -> CGRect? {
        let raw = CGWindowListCopyWindowInfo([.optionIncludingWindow], id) as? [[String: Any]] ?? []
        guard let dict = raw.first?[kCGWindowBounds as String] as? [String: Any] else { return nil }
        return CGRect(dictionaryRepresentation: dict as CFDictionary)
    }

    /// `point` is in CG space (top-left origin), as NSEvent.mouseLocation is not.
    public static func window(at point: CGPoint) -> WindowInfo? {
        onScreen().first { $0.bounds.contains(point) }
    }

    /// kCGWindowOwnerName is nil for other processes on macOS 26 without Screen Recording,
    /// and kCGWindowName always is. The running-application list is neither gated nor empty.
    public static func appName(_ pid: pid_t) -> String { regularName(pid) ?? "window" }

    /// NSRunningApplication lookups come back nil for a moment while another process is
    /// launching, which showed as every row reading "window" — so a resolved pid is kept.
    /// ponytail: never evicted, a recycled pid keeps the old name; key on launch date if it bites.
    private static var names: [pid_t: String] = [:]

    private static func regularName(_ pid: pid_t) -> String? {
        if let hit = names[pid] { return hit }
        guard let app = NSRunningApplication(processIdentifier: pid),
              app.activationPolicy == .regular, let name = app.localizedName else { return nil }
        names[pid] = name
        return name
    }

    /// Two windows of one app read the same without Screen Recording, since titles are
    /// gated and only the owning app's name comes back. Numbering them is what makes the
    /// list usable at all when a browser has three windows open.
    public static func choices(_ windows: [WindowInfo]) -> [WindowChoice] {
        var seen: [String: Int] = [:]
        var total: [String: Int] = [:]
        for w in windows { total[w.label, default: 0] += 1 }
        return windows.map { w in
            seen[w.label, default: 0] += 1
            let label = total[w.label]! > 1 ? "\(w.label) (\(seen[w.label]!))" : w.label
            return WindowChoice(window: w, label: label)
        }
    }
}

public struct WindowChoice: Identifiable, Equatable {
    public let window: WindowInfo
    public let label: String
    public var id: CGWindowID { window.id }
}
