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
