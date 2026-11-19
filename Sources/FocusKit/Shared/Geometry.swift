import CoreGraphics

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
