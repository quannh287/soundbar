import AppKit

/// CGWindow bounds are top-left origin in the global display space; AppKit is bottom-left.
/// `screenTop` is the maxY of the screen holding the menu bar, which is the origin screen.
public func cocoaRect(_ cg: CGRect, screenTop: CGFloat) -> CGRect {
    CGRect(x: cg.minX, y: screenTop - cg.maxY, width: cg.width, height: cg.height)
}

/// "0m", "42m", "1h 42m", "26h 5m" — never days, so a long session still reads as hours.
public func shortDuration(_ seconds: Double) -> String {
    let total = Int(max(0, seconds)) / 60
    let (h, m) = (total / 60, total % 60)
    return h > 0 ? "\(h)h \(m)m" : "\(m)m"
}

/// Which frame a window mostly sits on, by overlap rather than by its centre, so a
/// window straddling two displays still resolves to exactly one. nil when it touches none.
public func indexOfMostOverlap(_ rect: CGRect, in frames: [CGRect]) -> Int? {
    var best: (index: Int, area: CGFloat)?
    for (i, frame) in frames.enumerated() {
        let hit = frame.intersection(rect)
        guard !hit.isNull, !hit.isEmpty else { continue }
        let area = hit.width * hit.height
        if area > (best?.area ?? 0) { best = (i, area) }
    }
    return best?.index
}

/// `cg` is CGWindowList's top-left space.
public func screen(mostlyHolding cg: CGRect) -> NSScreen? {
    let screens = NSScreen.screens
    let top = screens.first?.frame.maxY ?? 0
    let rect = cocoaRect(cg, screenTop: top)
    return indexOfMostOverlap(rect, in: screens.map(\.frame)).map { screens[$0] }
}
