import AppKit
import Combine

/// Tracking is polled rather than event-driven: reading another app's window geometry
/// without Accessibility means asking CGWindowList, and nothing pushes. The timer only
/// exists while a session runs — idle cost stays zero.
let tickInterval: TimeInterval = 1.0 / 30

/// Geometry is polled at a third of the tick: every read is a full CGWindowList copy, and
/// 30 Hz of them cost ~8% of a core — the countdown needs the other ticks, tracking does not.
let trackInterval: TimeInterval = 1.0 / 10

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
    /// Published rather than computed so the open panel's countdown actually moves, and
    /// only when the text changes: once a minute, once a second in the last minute.
    @Published public private(set) var remainingLabel = ""
    @Published public private(set) var today: Double = FocusStats.load()[FocusStats.dayKey(Date())] ?? 0

    @Published public var minutes = UserDefaults.standard.object(forKey: "focusMinutes") as? Int ?? 25
    @Published public var presetName = UserDefaults.standard.string(forKey: "focusPreset")
    @Published public var mode = FocusMode(rawValue: UserDefaults.standard.string(forKey: "focusMode") ?? "") ?? .dim
    @Published public var intensity = UserDefaults.standard.object(forKey: "focusIntensity") as? Double ?? 0.75
    /// 0 means off. Drift is only meaningful because the target is pinned.
    @Published public var nudgeGrace = UserDefaults.standard.object(forKey: "focusGrace") as? Double ?? 5

    @Published public var pomodoro = UserDefaults.standard.bool(forKey: "focusPomodoro")
    /// Resting between blocks: the timer still runs, nothing is dimmed or counted.
    @Published public private(set) var onBreak = false
    /// Work blocks finished in this session, which is what picks the next break's length.
    @Published public private(set) var round = 0

    @Published public var fullScreen = UserDefaults.standard.bool(forKey: "focusFullScreen")
    /// Full screen was asked for and Accessibility is not granted to this build.
    @Published public private(set) var fullScreenBlocked = false

    public var onChange: (() -> Void)?

    private let mixer: Mixer
    private var overlays: [FocusOverlay] = []
    private var fullScreened: AXUIElement?
    private var tick: Timer?
    private var lastTrack = Date.distantPast
    private var peekUntil: Date?
    private var popoverOpen = false

    private var lastTick = Date()
    private var unflushed: Double = 0
    private var holes: [CGRect] = []
    private var lastLiveAt = Date()
    private var awaySince: Date?
    private var lastNudgeAt: Date?
    private var log: AttentionLog?
    private var startedAt = Date()
    private var nudges = 0
    private var peeks = 0
    /// NSRunningApplication lookup is not free at 30Hz, and a pid's name never changes.
    private var appNames: [pid_t: String] = [:]

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
        round = 0
        lastTick = Date()
        unflushed = 0
        appNames = [:]
        persist()
        beginWork()
        let timer = Timer(timeInterval: tickInterval, repeats: true) { _ in
            MainActor.assumeIsolated { self.onTick() }
        }
        // .default would stall the loop for as long as AppKit tracks events — menus,
        // window drags, and this app's own transient popover, which is where Start lives.
        RunLoop.main.add(timer, forMode: .common)
        tick = timer
    }

    /// Entered at Start and again after every break, so a resumed block gets its own
    /// log line, its own overlays and a fresh countdown.
    private func beginWork() {
        guard let first = targets.first else { return }
        let now = Date()
        fullScreenBlocked = fullScreen && !FullScreen.trusted(prompt: false)
        if fullScreen, !fullScreenBlocked, fullScreened == nil {
            fullScreened = FullScreen.enter(pid: first.pid,
                                            bounds: WindowTracker.bounds(of: first.id) ?? first.bounds)
        }
        onBreak = false
        lostTargets = false
        endsAt = minutes > 0 ? now.addingTimeInterval(Double(minutes) * 60) : nil
        lastLiveAt = now
        awaySince = nil
        lastNudgeAt = nil
        peekUntil = nil
        startedAt = now
        log = AttentionLog(start: now)
        nudges = 0
        peeks = 0
        remainingLabel = remaining.map { countdown($0) } ?? ""
        // Holes first: showing the overlays before the first tick computes them would
        // black the whole screen out, including the window being pinned.
        refreshHoles(now)
        rebuildOverlays()
        onChange?()
    }

    private func beginBreak() {
        flushStats()
        writeLog("pomodoro")
        round += 1
        onBreak = true
        fullScreened.map(FullScreen.exit)
        fullScreened = nil
        overlays.forEach { $0.retire() }
        overlays = []
        holes = []
        peekUntil = nil
        endsAt = Date().addingTimeInterval(Double(breakMinutes(afterRound: round)) * 60)
        remainingLabel = remaining.map { countdown($0) } ?? ""
        NSSound.beep()
        onChange?()
    }

    public func skipBreak() {
        guard running, onBreak else { return }
        beginWork()
    }

    public func stop(ended: String = "user") {
        guard running else { return }
        flushStats()
        writeLog(ended)
        tick?.invalidate()
        tick = nil
        onBreak = false
        round = 0
        fullScreened.map(FullScreen.exit)
        fullScreened = nil
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
        // Break time is neither dimmed nor credited to the day's focus total.
        if !onBreak {
            unflushed += elapsed
            if unflushed >= statsFlush { flushStats() }
            if now.timeIntervalSince(lastTrack) >= trackInterval {
                lastTrack = now
                updateHoles(now)
                checkDrift(now)
            }
        }

        if let endsAt, now >= endsAt {
            if onBreak {
                NSSound.beep()
                return beginWork()
            }
            if pomodoro, minutes > 0 { return beginBreak() }
            return stop(ended: "timer")
        }

        let label = remaining.map { countdown($0) } ?? ""
        if label != remainingLabel { remainingLabel = label }
        onChange?()
    }

    private func updateHoles(_ now: Date) {
        refreshHoles(now)

        // Not hidden for the panel: a popover window sits at level 25 and the overlay at
        // 19, so the panel was never underneath it. Only a deliberate peek hides it.
        let hidden = peekUntil.map { now < $0 } ?? false
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
        let frozen = lostTargets || popoverOpen || peekUntil != nil || NSApp.isActive
        let place: AttentionLog.Place = {
            guard !frozen, let front else { return .unknown }
            guard !targets.contains(where: { $0.id == front.id }), !inFullScreenTarget(front)
            else { return .target }
            return .away(appName(front.pid))
        }()
        // Sampled before the grace: a glance too short to nudge is still a switch, and
        // it is the kind this app could not see at all until now.
        log?.sample(place, at: now)

        guard nudgeGrace > 0, case .away = place, let front else { return awaySince = nil }

        let since = awaySince ?? now
        awaySince = since
        let sinceNudge = lastNudgeAt.map { now.timeIntervalSince($0) } ?? .infinity
        guard shouldNudge(awayFor: now.timeIntervalSince(since),
                          sinceLastNudge: sinceNudge, grace: nudgeGrace) else { return }
        lastNudgeAt = now
        nudges += 1
        let strayed = screen(mostlyHolding: front.bounds)
        for overlay in overlays {
            if overlay.screen === strayed { overlay.jolt() }
            overlay.flashRing()
        }
    }

    /// Asked when the box is ticked rather than at Start, so the trip to System Settings
    /// does not happen with a session already counting down.
    public func requestFullScreenAccess() {
        if fullScreen { _ = FullScreen.trusted(prompt: true) }
    }

    private func inFullScreenTarget(_ front: WindowInfo) -> Bool {
        guard fullScreened != nil, let pinned = targets.first,
              let bounds = WindowTracker.bounds(of: pinned.id) else { return false }
        return WindowTracker.isPart(front, of: pinned, at: bounds)
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
        peeks += 1
        awaySince = nil
    }

    public func setPopoverOpen(_ open: Bool) {
        popoverOpen = open
        guard open else { return }
        awaySince = nil
        refreshCandidates()
    }

    // MARK: plumbing

    public var remaining: TimeInterval? {
        guard let endsAt else { return nil }
        return max(0, endsAt.timeIntervalSinceNow)
    }

    private func appName(_ pid: pid_t) -> String {
        if let cached = appNames[pid] { return cached }
        let name = WindowTracker.appName(pid)
        appNames[pid] = name
        return name
    }

    private func writeLog(_ ended: String) {
        guard var log else { return }
        let now = Date()
        log.finish(at: now)
        SessionLog.append(SessionLog.line(log, start: startedAt, end: now,
                                          planned: minutes, targets: targets.count,
                                          mode: mode.rawValue, preset: presetName,
                                          nudges: nudges, peeks: peeks, ended: ended))
        self.log = nil
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
        overlays.forEach { $0.update(holes: holes) }
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
        d.set(fullScreen, forKey: "focusFullScreen")
        d.set(pomodoro, forKey: "focusPomodoro")
    }
}
