import AppKit

/// Three bars scaling under one CABasicAnimation each. The compositor runs them, so the
/// app burns no CPU per frame — assigning button.image on a timer cost 2.5% of a core.
let barsWidth: CGFloat = 15
let barsInset: CGFloat = 6
let barsItemLength: CGFloat = barsWidth + barsInset * 2

func installBars(on button: NSStatusBarButton) {
    button.image = nil
    button.wantsLayer = true
    let host = CALayer()
    host.name = "eq"
    host.frame = CGRect(x: barsInset, y: 5, width: barsWidth, height: 16)
    button.layer?.addSublayer(host)

    for i in 0 ..< 3 {
        let bar = CALayer()
        bar.backgroundColor = NSColor.labelColor.cgColor
        bar.cornerRadius = 1.5
        bar.frame = CGRect(x: CGFloat(i) * 5.5, y: 1.5, width: 3, height: 13)
        host.addSublayer(bar)

        let pulse = CABasicAnimation(keyPath: "transform.scale.y")
        pulse.fromValue = 0.35 + 0.2 * Double(i)
        pulse.toValue = 1.0
        // Durations deliberately not multiples of each other, or the bars march in step.
        pulse.duration = 0.6 + 0.17 * Double(i)
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        bar.add(pulse, forKey: "eq")
    }
}

/// Same compositor-driven trick as the bars, so a running session reads as live without
/// the per-frame cost of reassigning button.image on the tick.
func installPulse(on button: NSStatusBarButton, symbol: String, label: String) {
    guard let glyph = NSImage(systemSymbolName: symbol, accessibilityDescription: label) else { return }
    // A blank image of the glyph's size keeps AppKit laying the title out after it.
    let blank = NSImage(size: NSSize(width: barsWidth, height: 16), flipped: false) { _ in true }
    blank.accessibilityDescription = label
    button.image = blank
    button.wantsLayer = true

    let host = CALayer()
    host.name = "eq"
    host.frame = CGRect(x: barsInset, y: 3, width: barsWidth, height: 16)
    // A layer never picks up the template tint, so the colour is painted and masked by the symbol.
    host.backgroundColor = NSColor.labelColor.cgColor
    let mask = CALayer()
    mask.frame = host.bounds
    mask.contents = glyph
    mask.contentsGravity = .resizeAspect
    host.mask = mask
    button.layer?.addSublayer(host)

    // Scale alone is invisible on a 15pt glyph; the fade is what the eye actually catches.
    for (key, from, to) in [("transform.scale", 0.68, 1.06), ("opacity", 0.35, 1.0)] {
        let breathe = CABasicAnimation(keyPath: key)
        breathe.fromValue = from
        breathe.toValue = to
        breathe.duration = 1.1
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        host.add(breathe, forKey: key)
    }
}
