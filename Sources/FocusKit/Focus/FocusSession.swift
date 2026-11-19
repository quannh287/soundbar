import AppKit
import Combine

/// Tracking is polled rather than event-driven: reading another app's window geometry
/// without Accessibility means asking CGWindowList, and nothing pushes. The timer only
/// exists while a session runs — idle cost stays zero.
let tickInterval: TimeInterval = 1.0 / 30

/// CG reports no bounds while a window animates into or out of full screen. Without this
/// grace the screen blacks out for the length of that animation.
let lostGrace: TimeInterval = 1.0

/// Flush interval for the day total. A crash costs at most this much, and crediting
/// "now" rather than the session start is what splits a session across midnight.
let statsFlush: TimeInterval = 60

@MainActor
public final class FocusSession: ObservableObject {
    @Published public private(set) var running = false
    @Published public private(set) var endsAt: Date?
    @Published public private(set) var targets: [WindowInfo] = []
    @Published public private(set) var lostTargets = false
    @Published public private(set) var candidates: [WindowChoice] = []
    /// The window Start will pin. Seeded from whatever was frontmost when the panel
    /// opened, then overridable from the list.
    @Published public var candidate: WindowInfo?
    /// Published rather than computed so the open panel's countdown actually moves —
    /// and only when the minute changes, which keeps it to one republish a minute.
    @Published public private(set) var remainingLabel = ""
    @Published public private(set) var today: Double = FocusStats.load()[FocusStats.dayKey(Date())] ?? 0

    @Published public var minutes = UserDefaults.standard.object(forKey: "focusMinutes") as? Int ?? 25
    @Published public var presetName = UserDefaults.standard.string(forKey: "focusPreset")
    @Published public var mode = FocusMode(rawValue: UserDefaults.standard.string(forKey: "focusMode") ?? "") ?? .dim
    @Published public var intensity = UserDefaults.standard.object(forKey: "focusIntensity") as? Double ?? 0.75
    /// 0 means off. Drift is only meaningful because the target is pinned.
    @Published public var nudgeGrace = UserDefaults.standard.object(forKey: "focusGrace") as? Double ?? 5

    public var onChange: (() -> Void)?

    private let mixer: Mixer
    private var overlays: [FocusOverlay] = []
    private var tick: Timer?
    private var peekUntil: Date?
    private var popoverOpen = false

    private var lastTick = Date()
    private var unflushed: Double = 0
    private var holes: [CGRect] = []
    private var lastLiveAt = Date()
    private var awaySince: Date?
    private var lastNudgeAt: Date?

    public init(mixer: Mixer) {
        self.mixer = mixer
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in MainActor.assumeIsolated { self?.rebuildOverlays() } }
    }

    // MARK: lifecycle

    public func start() {
        guard !running, let first = candidate ?? WindowTracker.frontmost() else { return }
        targets = [first]
        if let name = presetName, let preset = mixer.presets.first(where: { $0.name == name }) {
            mixer.apply(preset)
        }
        running = true
        lostTargets = false
        endsAt = minutes > 0 ? Date().addingTimeInterval(Double(minutes) * 60) : nil
        lastTick = Date()
        lastLiveAt = lastTick
        unflushed = 0
        awaySince = nil
        lastNudgeAt = nil
        remainingLabel = remaining.map { shortDuration($0) } ?? ""
        persist()
        // Holes first: showing the overlays before the first tick computes them would
        // black the whole screen out, including the window being pinned.
        refreshHoles(Date())
        rebuildOverlays()
        let timer = Timer(timeInterval: tickInterval, repeats: true) { _ in
            MainActor.assumeIsolated { self.onTick() }
        }
        // .default would stall the loop for as long as AppKit tracks events — menus,
        // window drags, and this app's own transient popover, which is where Start lives.
        RunLoop.main.add(timer, forMode: .common)
        tick = timer
        onChange?()
    }

    public func stop() {
        guard running else { return }
        flushStats()
        tick?.invalidate()
        tick = nil
        overlays.forEach { $0.retire() }
        overlays = []
        targets = []
        holes = []
        running = false
        endsAt = nil
        remainingLabel = ""
        peekUntil = nil
        mixer.stopAll()
        onChange?()
    }

    // MARK: the one loop

    private func onTick() {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTick)
        lastTick = now
        unflushed += elapsed
        if unflushed >= statsFlush { flushStats() }

        updateHoles(now)
        checkDrift(now)

        if let endsAt, now >= endsAt { return stop() }

        let label = remaining.map { shortDuration($0) } ?? ""
        if label != remainingLabel { remainingLabel = label }
        onChange?()
    }

    private func updateHoles(_ now: Date) {
        refreshHoles(now)

        let hidden = popoverOpen || (peekUntil.map { now < $0 } ?? false)
        if let peekUntil, now >= peekUntil { self.peekUntil = nil }
        for overlay in overlays {
            overlay.setHidden(hidden)
            overlay.update(holes: holes)
        }
    }

    private func refreshHoles(_ now: Date) {
        let top = NSScreen.screens.first?.frame.maxY ?? 0
        let live = targets.compactMap { WindowTracker.bounds(of: $0.id) }
            .map { cocoaRect($0, screenTop: top) }

        var lost = lostTargets
        if !live.isEmpty {
            holes = live
            lastLiveAt = now
            lost = false
        } else if now.timeIntervalSince(lastLiveAt) >= lostGrace {
            // Inside the grace the last known holes stand: the window is most likely
            // mid-animation rather than gone.
            holes = []
            lost = true
        }
        // Assigning a @Published every tick republishes even when nothing changed,
        // which re-renders the open panel 30 times a second.
        if lost != lostTargets { lostTargets = lost }
    }

    private func checkDrift(_ now: Date) {
        let front = WindowTracker.frontmost()
        let suppressed = nudgeGrace <= 0 || lostTargets || popoverOpen
            || peekUntil != nil || NSApp.isActive || front == nil
        guard !suppressed, let front else { return awaySince = nil }
        guard !targets.contains(where: { $0.id == front.id }) else { return awaySince = nil }

        let since = awaySince ?? now
        awaySince = since
        let sinceNudge = lastNudgeAt.map { now.timeIntervalSince($0) } ?? .infinity
        guard shouldNudge(awayFor: now.timeIntervalSince(since),
                          sinceLastNudge: sinceNudge, grace: nudgeGrace) else { return }
        lastNudgeAt = now
        overlays.forEach { $0.shake() }
    }

    // MARK: targets

    public func add(_ window: WindowInfo) {
        guard running, !targets.contains(where: { $0.id == window.id }) else { return }
        targets.append(window)
    }

    public func drop(_ id: CGWindowID) {
        guard targets.count > 1 else { return }
        targets.removeAll { $0.id == id }
    }

    /// Titles go stale the moment a browser tab changes, so the list is rebuilt when the
    /// panel opens — the only time anyone can read it — rather than on every tick.
    public func refreshCandidates() {
        let live = WindowTracker.onScreen()
        candidates = WindowTracker.choices(live)
        if candidate == nil || !live.contains(where: { $0.id == candidate?.id }) {
            candidate = live.first
        }
        for i in targets.indices {
            guard let match = live.first(where: { $0.id == targets[i].id }) else { continue }
            targets[i].title = match.title
        }
    }

    // MARK: peek

    public func peek(_ seconds: TimeInterval = 10) {
        guard running else { return }
        peekUntil = Date().addingTimeInterval(seconds)
        awaySince = nil
    }

    /// The panel itself sits under the overlay, so the overlay steps aside while it is open.
    public func setPopoverOpen(_ open: Bool) {
        popoverOpen = open
        if open {
            awaySince = nil
            refreshCandidates()
        }
        guard running else { return }
        overlays.forEach { $0.setHidden(open) }
    }

    // MARK: plumbing

    public var remaining: TimeInterval? {
        guard let endsAt else { return nil }
        return max(0, endsAt.timeIntervalSinceNow)
    }

    private func flushStats() {
        guard unflushed > 0 else { return }
        FocusStats.record(unflushed)
        unflushed = 0
        today = FocusStats.load()[FocusStats.dayKey(Date())] ?? 0
    }

    private func rebuildOverlays() {
        overlays.forEach { $0.retire() }
        guard running else { return overlays = [] }
        overlays = NSScreen.screens.map { FocusOverlay(screen: $0, mode: mode, intensity: intensity) }
        for overlay in overlays {
            overlay.update(holes: holes)
            // Start is pressed from inside the panel, so the panel is open right now and
            // the overlay would otherwise cover the thing the user is looking at.
            overlay.setHidden(popoverOpen)
        }
    }

    public func applyAppearance() {
        persist()
        // Mode is baked into each overlay's content view, so a change means new overlays.
        rebuildOverlays()
    }

    public func applyIntensity() {
        persist()
        overlays.forEach { $0.setIntensity(intensity) }
    }

    public func persist() {
        let d = UserDefaults.standard
        d.set(minutes, forKey: "focusMinutes")
        d.set(presetName, forKey: "focusPreset")
        d.set(mode.rawValue, forKey: "focusMode")
        d.set(intensity, forKey: "focusIntensity")
        d.set(nudgeGrace, forKey: "focusGrace")
    }
}
