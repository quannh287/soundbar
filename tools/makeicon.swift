import AppKit

// Renders AppIcon.icns. Run once after changing the artwork; the result is committed.
let canvas: CGFloat = 1024
let inset: CGFloat = 100 // macOS icons sit in a padded squircle, not edge to edge
let plate = NSRect(x: inset, y: inset, width: canvas - inset * 2, height: canvas - inset * 2)

let image = NSImage(size: NSSize(width: canvas, height: canvas), flipped: false) { _ in
    let squircle = NSBezierPath(roundedRect: plate,
                                xRadius: plate.width * 0.2237, yRadius: plate.width * 0.2237)
    squircle.addClip()
    NSGradient(colors: [NSColor(srgbRed: 0.09, green: 0.47, blue: 0.82, alpha: 1),
                        NSColor(srgbRed: 0.18, green: 0.78, blue: 0.75, alpha: 1)])?
        .draw(in: plate, angle: -90)

    NSColor.white.setFill()
    let heights: [CGFloat] = [0.5, 1.0, 0.72]
    let barWidth = plate.width * 0.1
    let gap = plate.width * 0.07
    let span = barWidth * 3 + gap * 2
    for (i, f) in heights.enumerated() {
        let h = plate.height * 0.62 * f
        let bar = NSRect(x: plate.midX - span / 2 + CGFloat(i) * (barWidth + gap),
                         y: plate.midY - h / 2, width: barWidth, height: h)
        NSBezierPath(roundedRect: bar, xRadius: barWidth / 2, yRadius: barWidth / 2).fill()
    }
    return true
}

let png = NSBitmapImageRep(data: image.tiffRepresentation!)!.representation(using: .png, properties: [:])!
try png.write(to: URL(fileURLWithPath: "icon1024.png"))
