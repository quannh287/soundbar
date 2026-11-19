import AppKit

public enum FocusMode: String, CaseIterable, Identifiable {
    case dim, blur
    public var id: String { rawValue }
    public var label: String { rawValue.capitalized }
}

/// Calibration knob: macOS window corner radii vary by window style and OS version.
let holeCornerRadius: CGFloat = 10

/// The dim plane is drawn larger than the screen by this much on every side, so shaking
/// it never slides an undimmed strip in at an edge.
let shakeOverscan: CGFloat = 28

/// A text-field shake is 8-10pt; across a 1920px screen that is half a percent and reads
/// as nothing. The displacement is bigger and a deepening pulse carries most of the signal.
let shakeSteps: [CGFloat] = [0, -22, 18, -14, 10, -6, 0]

/// One click-through window per screen, punched through where the pinned windows are.
///
/// There is no public way to slip a window *between* another app's windows:
/// orderWindow(_:relativeTo:) is same-process only and window levels are coarse buckets.
/// So the overlay covers everything and the hole is cut out of it.
@MainActor
final class FocusOverlay {
    private let window: NSWindow
    /// Screen-sized and clipped by the window; only holds the plane.
    private let container = NSView()
    /// Overscanned, masked, and the thing that actually moves.
    private let content: NSView
    private let shape = CAShapeLayer()
    private let mode: FocusMode
    /// Optional, not an empty array: a screen holding none of the pinned windows has no
    /// holes, and "no holes yet" has to differ from "no holes" or the first update is
    /// skipped and the mask layer keeps its nil path, which hides the overlay entirely.
    private var holes: [CGRect]?
    private var hidden = false
    private var intensity: Double = 0.75
    let screen: NSScreen

    init(screen: NSScreen, mode: FocusMode, intensity: Double) {
        self.screen = screen
        self.mode = mode
        window = NSWindow(contentRect: screen.frame, styleMask: .borderless,
                          backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        // One below the Dock (20), so the Dock and the menu bar draw over the overlay and
        // are never dimmed — the menu bar is this app's only UI and must stay reachable
        // even if a hole lands in the wrong place.
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) - 1)
        // Without .transient the overlay stays up over Mission Control; with
        // .fullScreenAuxiliary it covers full-screen spaces and blacks the display out.
        window.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle]
        // Click-through is the whole point: dimmed windows must stay usable, because the
        // background is where the agent sessions are running.
        window.ignoresMouseEvents = true
        // Deliberately NOT sharingType = .none. Excluding the overlay from screen capture
        // keeps screenshots undimmed, but a DisplayLink monitor — what a dual-HDMI USB-C
        // hub drives on Apple silicon — is itself painted from a capture of a virtual
        // display, so an excluded window simply never appears on it.
        window.appearance = NSAppearance(named: .darkAqua)

        let local = screen.frame.offsetBy(dx: -screen.frame.minX, dy: -screen.frame.minY)
        container.frame = local
        container.wantsLayer = true

        switch mode {
        case .dim:
            let view = NSView(frame: local.insetBy(dx: -shakeOverscan, dy: -shakeOverscan))
            view.wantsLayer = true
            view.layer?.backgroundColor = NSColor.black.cgColor
            shape.fillRule = .evenOdd
            view.layer?.mask = shape
            content = view
        case .blur:
            let view = NSVisualEffectView(frame: local.insetBy(dx: -shakeOverscan,
                                                               dy: -shakeOverscan))
            view.blendingMode = .behindWindow
            view.material = .fullScreenUI
            // Required: the overlay is never the key window, and the default state
            // disables the effect entirely for an inactive window.
            view.state = .active
            content = view
        }
        container.addSubview(content)
        window.contentView = container
        // Intensity belongs on the view, never on the window: a window alphaValue below 1
        // is a known way to lose the behind-window blur altogether.
        content.alphaValue = intensity
        self.intensity = intensity
        window.orderFrontRegardless()
    }

    /// `rects` are global AppKit coordinates; empty means dim the whole screen.
    func update(holes rects: [CGRect]) {
        let bounds = content.bounds
        // The plane's origin sits at -shakeOverscan in screen space, so every hole shifts
        // by the same amount to stay over the window it belongs to.
        let local = rects.compactMap { rect -> CGRect? in
            let r = rect.offsetBy(dx: -screen.frame.minX + shakeOverscan,
                                  dy: -screen.frame.minY + shakeOverscan)
                .intersection(bounds)
            return r.isNull || r.isEmpty ? nil : r
        }
        // Redrawing a full-screen mask image 30 times a second for an unchanged hole is
        // the one genuinely expensive thing this loop could do.
        guard local != holes else { return }
        holes = local

        switch mode {
        case .dim:
            let path = CGMutablePath()
            path.addRect(bounds)
            for hole in local {
                path.addRoundedRect(in: hole, cornerWidth: holeCornerRadius,
                                    cornerHeight: holeCornerRadius)
            }
            // Without this the hole animates to each new position over the default 0.25s
            // and visibly trails the window while it is being dragged.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            shape.frame = bounds
            shape.path = path
            CATransaction.commit()
        case .blur:
            // NSVisualEffectView ignores layer.mask; maskImage is the supported cutout.
            let path = NSBezierPath(rect: bounds)
            for hole in local {
                path.append(NSBezierPath(roundedRect: hole, xRadius: holeCornerRadius,
                                         yRadius: holeCornerRadius))
            }
            path.windingRule = .evenOdd
            (content as? NSVisualEffectView)?.maskImage =
                NSImage(size: bounds.size, flipped: false) { _ in
                    NSColor.black.setFill()
                    path.fill()
                    return true
                }
        }
    }

    func setIntensity(_ value: Double) {
        intensity = value
        content.alphaValue = value
    }

    /// Core Animation runs both of these on the compositor at the display's refresh rate.
    /// Driving them from the 30 Hz tracking tick instead gave about thirteen frames, which
    /// read as a stutter rather than a shake.
    func shake() {
        guard let layer = content.layer else { return }
        let origin = layer.position
        let slide = CAKeyframeAnimation(keyPath: "position")
        slide.values = shakeSteps.map { NSValue(point: CGPoint(x: origin.x + $0, y: origin.y)) }
        slide.duration = 0.5
        slide.timingFunction = CAMediaTimingFunction(name: .easeOut)
        layer.add(slide, forKey: "nudgeSlide")

        // The displacement alone is subtle at screen scale; the darkening is what catches
        // the eye, and it costs nothing extra.
        let base = Float(intensity)
        let pulse = CAKeyframeAnimation(keyPath: "opacity")
        pulse.values = [base, min(1, base * 1.7), min(1, base * 1.3), base]
        pulse.keyTimes = [0, 0.15, 0.4, 1]
        pulse.duration = 0.5
        layer.add(pulse, forKey: "nudgePulse")
    }

    func setHidden(_ value: Bool) {
        guard value != hidden else { return }
        hidden = value
        if value { window.orderOut(nil) } else { window.orderFrontRegardless() }
    }

    /// orderOut, never close(): closing a live overlay has been reported to crash.
    func retire() { window.orderOut(nil) }
}
