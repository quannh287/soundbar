import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mixer = Mixer()
    private lazy var session = FocusSession(mixer: mixer)
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var shown: Bar?

    /// What the status item is currently showing. Compared before touching the button,
    /// because rebuilding it on every tick is exactly the per-frame work worth avoiding.
    private enum Bar: Equatable {
        case focus
        case onBreak
        case playing
        case idle
    }

    override public init() { super.init() }

    public func applicationDidFinishLaunching(_: Notification) {
        replaceOtherInstances()
        popover.behavior = .transient
        popover.delegate = self
        item.button?.target = self
        item.button?.action = #selector(toggle)
        // A transient popover does not reliably close itself for an accessory app, so
        // losing active status is what dismisses it when you click another window.
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.popover.performClose(nil) }
        }
        mixer.onPlayingChange = { [weak self] in self?.refreshStatus() }
        session.onChange = { [weak self] in self?.refreshStatus() }
        refreshStatus()
    }

    /// Quitting mid-session otherwise drops the whole log line and up to a minute of
    /// unflushed stats. A no-op when nothing is running.
    public func applicationWillTerminate(_: Notification) { session.stop(ended: "quit") }

    /// brew upgrade cannot touch the copy already running, so opening the new one must
    /// retire the old one — otherwise both play and the volumes add up.
    private func replaceOtherInstances() {
        guard let id = Bundle.main.bundleIdentifier else { return }
        let me = ProcessInfo.processInfo.processIdentifier
        for other in NSRunningApplication.runningApplications(withBundleIdentifier: id)
            where other.processIdentifier != me {
            other.terminate()
        }
    }

    /// Built on first open, not at launch: sizingOptions forces SwiftUI to lay the whole
    /// panel out to report a content size, and a menu bar app is often never opened.
    private func preparePopover() {
        guard popover.contentViewController == nil else { return }
        let host = NSHostingController(rootView: RootPanel(mixer: mixer, session: session))
        // Without this the popover keeps its own default size and clips the panel's top padding.
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
    }

    @objc private func toggle() {
        guard let button = item.button else { return }
        if popover.isShown { return popover.performClose(nil) }
        preparePopover()
        // Read the window stack before activating: one frame later the frontmost window
        // is this app's own, and the thing the user wanted to pin is second.
        if !session.running { session.candidate = WindowTracker.frontmost() }
        // LSMinimumSystemVersion says 13.0, and the no-argument activate() is 14+.
        if #available(macOS 14.0, *) { NSApp.activate() } else { NSApp.activate(ignoringOtherApps: true) }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // SwiftUI hands first responder to the segmented picker on open, and the focus ring
        // is drawn by AppKit in the system accent, which no .tint reaches. Dropping the
        // responder clears it; Tab still brings it back for keyboard users.
        popover.contentViewController?.view.window?.makeFirstResponder(nil)
    }

    private func refreshStatus() {
        guard let button = item.button else { return }
        let next: Bar
        if session.running {
            next = session.onBreak ? .onBreak : .focus
        } else {
            next = mixer.mix.isEmpty ? .idle : .playing
        }
        // Set apart from the icon, which rebuilding on the tick would re-animate — and only
        // on a change, or the cell redraws 30 times a second for the same string.
        let title = session.running ? " \(session.remainingLabel)" : ""
        if button.title != title { button.title = title }
        guard next != shown else { return }
        shown = next

        button.layer?.sublayers?.filter { $0.name == "eq" }.forEach { $0.removeFromSuperlayer() }
        button.imagePosition = .imageLeading
        switch next {
        case .focus:
            item.length = NSStatusItem.variableLength
            installPulse(on: button, symbol: "scope", label: "Focusing")
        case .onBreak:
            item.length = NSStatusItem.variableLength
            button.image = NSImage(systemSymbolName: "cup.and.saucer",
                                   accessibilityDescription: "On a break")
        case .playing:
            // Without an image a variable-length item collapses and clips the layers.
            item.length = barsItemLength
            button.image = nil
            installBars(on: button)
        case .idle:
            item.length = NSStatusItem.variableLength
            button.image = NSImage(systemSymbolName: "water.waves.slash", accessibilityDescription: "Sounds")
        }
    }
}

extension AppDelegate: NSPopoverDelegate {
    public nonisolated func popoverDidShow(_: Notification) {
        MainActor.assumeIsolated { session.setPopoverOpen(true) }
    }

    public nonisolated func popoverDidClose(_: Notification) {
        MainActor.assumeIsolated { session.setPopoverOpen(false) }
    }
}
