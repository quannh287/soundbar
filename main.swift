import AVFoundation
import ServiceManagement
import SwiftUI

let catalogURL = URL(string: "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_ComfortSoundsAssets/com_apple_MobileAsset_ComfortSoundsAssets.xml")!
let systemAssets = URL(fileURLWithPath: "/System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets")
let cacheDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("SoundBar")

struct Sound: Identifiable, Hashable {
    let name: String
    let url: URL
    let bytes: Int
    var id: String { name }

    var symbol: String {
        let s = [
            "PinkNoise": "waveform", "WhiteNoise": "waveform.path", "BrownNoise": "waveform.path.ecg",
            "Ocean": "water.waves", "Rain": "cloud.rain", "Stream": "drop", "Night": "moon.stars",
            "Fire": "flame", "Babble": "person.2.wave.2", "Steam": "cloud.fog", "Airplane": "airplane",
            "Boat": "sailboat", "Bus": "bus", "Train": "tram", "RainOnRoof": "cloud.heavyrain",
            "QuietNight": "moon.zzz",
        ][name] ?? "waveform"
        return NSImage(systemSymbolName: s, accessibilityDescription: nil) == nil ? "waveform" : s
    }
}

struct Preset: Identifiable, Hashable {
    let name: String
    let mix: [String: Float]
    var builtin = false
    var id: String { name }

    /// Every mix is one deep base plus a lighter layer over it — the shape every
    /// ambient mixer converges on, because two sounds at equal weight fight each other.
    static let builtin: [Preset] = [
        Preset(name: "Deep Work", mix: ["BrownNoise": 0.7, "Rain": 0.3], builtin: true),
        Preset(name: "Cafe", mix: ["Babble": 0.5, "Rain": 0.3], builtin: true),
        Preset(name: "Cozy", mix: ["Fire": 0.55, "RainOnRoof": 0.4], builtin: true),
        Preset(name: "Sleep", mix: ["Ocean": 0.5, "QuietNight": 0.35], builtin: true),
        Preset(name: "Night", mix: ["Night": 0.55, "Stream": 0.25], builtin: true),
        Preset(name: "Flight", mix: ["Airplane": 0.6, "PinkNoise": 0.25], builtin: true),
    ]
}

func m4as(in dir: URL) -> [URL] {
    let f = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
    return f.filter { $0.pathExtension == "m4a" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
}

/// Apple's own installed copy, so a sound the system already downloaded is never fetched twice.
func installedFiles(_ name: String) -> [URL] {
    let dirs = (try? FileManager.default.contentsOfDirectory(at: systemAssets, includingPropertiesForKeys: nil)) ?? []
    for d in dirs where d.pathExtension == "asset" {
        guard let info = NSDictionary(contentsOf: d.appendingPathComponent("Info.plist")),
              let props = info["MobileAssetProperties"] as? [String: Any],
              props["SoundName"] as? String == name else { continue }
        return m4as(in: d.appendingPathComponent("AssetData"))
    }
    return []
}

func localFiles(_ name: String) -> [URL] {
    let own = m4as(in: cacheDir.appendingPathComponent(name))
    return own.isEmpty ? installedFiles(name) : own
}

/// One AVAudioEngine for every sound, not one player each: N players means N pipelines
/// into coreaudiod, and coreaudiod's share of the CPU scaled with them.
@MainActor
final class Engine {
    private let engine = AVAudioEngine()
    private var nodes: [String: AVAudioPlayerNode] = [:]
    private var files: [String: [URL]] = [:]

    var master: Float = 1 {
        didSet { engine.mainMixerNode.outputVolume = master }
    }

    func add(_ name: String, volume: Float) {
        if let node = nodes[name] { return node.volume = volume }
        let list = localFiles(name)
        guard !list.isEmpty, let probe = try? AVAudioFile(forReading: list[0]) else { return }

        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: probe.processingFormat)
        nodes[name] = node
        files[name] = list
        node.volume = volume

        engine.mainMixerNode.outputVolume = master
        if !engine.isRunning { try? engine.start() }
        schedule(name, count: 2)
        node.play()
    }

    func remove(_ name: String) {
        guard let node = nodes.removeValue(forKey: name) else { return }
        files[name] = nil
        node.stop()
        engine.detach(node)
        if nodes.isEmpty { engine.stop() }
    }

    func setVolume(_ name: String, _ volume: Float) { nodes[name]?.volume = volume }

    func stopAll() { for name in nodes.keys { remove(name) } }

    /// Apple ships each sound as interchangeable variations; shuffling them avoids an
    /// audible loop point. Two are always queued so the seam has no gap.
    private func schedule(_ name: String, count: Int) {
        guard let node = nodes[name], let list = files[name] else { return }
        for _ in 0 ..< count {
            guard let url = list.randomElement(), let file = try? AVAudioFile(forReading: url) else { continue }
            node.scheduleFile(file, at: nil, completionCallbackType: .dataPlayedBack) { [weak self] _ in
                Task { @MainActor in self?.schedule(name, count: 1) }
            }
        }
    }
}

@MainActor
final class Mixer: NSObject, ObservableObject {
    @Published var catalog: [Sound] = []
    @Published var mix: [String: Float] = [:]
    @Published var progress: [String: Double] = [:]
    @Published var master: Float = UserDefaults.standard.object(forKey: "master") as? Float ?? 0.7
    @Published var muteAt: Date?
    @Published var atLogin = SMAppService.mainApp.status == .enabled
    @Published var downloaded: Set<String> = []
    var onPlayingChange: (() -> Void)?
    @Published var userPresets: [Preset] = []

    var presets: [Preset] { Preset.builtin + userPresets }

    private let engine = Engine()
    private var timer: Timer?

    override init() {
        super.init()
        if let d = UserDefaults.standard.dictionary(forKey: "mix") as? [String: Double] {
            mix = d.mapValues { Float($0) }
        }
        loadPresets()
        loadCatalog()
    }

    // MARK: catalog

    func loadCatalog(_ done: (() -> Void)? = nil) {
        URLSession.shared.dataTask(with: catalogURL) { data, _, _ in
            guard let data,
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let raw = plist["Assets"] as? [[String: Any]] else { return }
            var seen: [String: Sound] = [:]
            var group: [String: Int] = [:]
            for a in raw {
                guard let name = a["SoundName"] as? String, seen[name] == nil,
                      let base = a["__BaseURL"] as? String, let rel = a["__RelativePath"] as? String,
                      let url = URL(string: base + rel) else { continue }
                seen[name] = Sound(name: name, url: url, bytes: a["_DownloadSize"] as? Int ?? 0)
                group[name] = a["SoundGroup"] as? Int ?? 99
            }
            // SoundGroup is Apple's own ordering, matching the Settings picker.
            let sorted = seen.keys.sorted { group[$0]! < group[$1]! }
            Task { @MainActor in
                self.catalog = sorted.compactMap { seen[$0] }
                self.refreshDownloaded()
                self.resume()
                done?()
            }
        }.resume()
    }

    // MARK: mixing

    func isOn(_ name: String) -> Bool { mix[name] != nil }

    func toggle(_ s: Sound) {
        guard isOn(s.name) else { return enable(s, volume: 0.8) }
        mix[s.name] = nil
        engine.remove(s.name)
        persist()
    }

    fileprivate func enable(_ s: Sound, volume: Float) {
        guard !localFiles(s.name).isEmpty else { return download(s, volume: volume) }
        mix[s.name] = volume
        engine.add(s.name, volume: volume)
        persist()
    }

    // MARK: presets

    func apply(_ preset: Preset) {
        stopAll()
        for (name, volume) in preset.mix {
            guard let s = catalog.first(where: { $0.name == name }) else { continue }
            enable(s, volume: volume)
        }
    }

    func savePreset(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, !mix.isEmpty, !Preset.builtin.contains(where: { $0.name == clean }) else { return }
        var stored = UserDefaults.standard.dictionary(forKey: "presets") as? [String: [String: Double]] ?? [:]
        stored[clean] = mix.mapValues { Double($0) }
        UserDefaults.standard.set(stored, forKey: "presets")
        loadPresets()
    }

    func renamePreset(_ old: String, to new: String) {
        let clean = new.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, clean != old,
              !Preset.builtin.contains(where: { $0.name == clean }) else { return }
        var stored = UserDefaults.standard.dictionary(forKey: "presets") as? [String: [String: Double]] ?? [:]
        guard let saved = stored[old] else { return }
        stored[old] = nil
        stored[clean] = saved
        UserDefaults.standard.set(stored, forKey: "presets")
        loadPresets()
    }

    func deletePreset(_ name: String) {
        var stored = UserDefaults.standard.dictionary(forKey: "presets") as? [String: [String: Double]] ?? [:]
        stored[name] = nil
        UserDefaults.standard.set(stored, forKey: "presets")
        loadPresets()
    }

    /// Tile bodies must never stat the filesystem: 16 tiles x 4 frames a second is 64
    /// directory scans plus Info.plist reads per second.
    private func refreshDownloaded() {
        downloaded = Set(catalog.map(\.name).filter { !localFiles($0).isEmpty })
    }

    private func loadPresets() {
        let stored = UserDefaults.standard.dictionary(forKey: "presets") as? [String: [String: Double]] ?? [:]
        userPresets = stored.keys.sorted().map { Preset(name: $0, mix: stored[$0]!.mapValues { Float($0) }) }
    }

    func setVolume(_ name: String, _ v: Float) {
        mix[name] = v
        engine.setVolume(name, v)
        persist()
    }

    func setMaster(_ v: Float) {
        master = v
        engine.master = v
        persist()
    }

    /// Restart whatever was playing when the app last quit.
    private func resume() {
        engine.master = master
        for (name, vol) in mix { engine.add(name, volume: vol) }
        onPlayingChange?()
    }

    func stopAll() {
        engine.stopAll()
        mix.removeAll()
        muteAt = nil
        timer?.invalidate()
        persist()
    }

    private func persist() {
        onPlayingChange?()
        UserDefaults.standard.set(mix.mapValues { Double($0) }, forKey: "mix")
        UserDefaults.standard.set(master, forKey: "master")
    }

    func setLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("SoundBar: login item \(on ? "register" : "unregister") failed: \(error)")
        }
        // Read back rather than trusting the call: an unsigned or relocated bundle silently stays off.
        atLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: timer

    func mute(after minutes: Int?) {
        timer?.invalidate()
        guard let minutes else { muteAt = nil; return }
        muteAt = Date().addingTimeInterval(Double(minutes) * 60)
        timer = Timer.scheduledTimer(withTimeInterval: Double(minutes) * 60, repeats: false) { _ in
            Task { @MainActor in self.stopAll() }
        }
    }

    // MARK: download

    func download(_ s: Sound, volume: Float = 0.8) {
        guard progress[s.name] == nil else { return }
        progress[s.name] = 0
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        session.downloadTask(with: s.url) { tmp, _, _ in
            if let tmp { unpack(tmp, into: s.name) }
            Task { @MainActor in
                self.progress[s.name] = nil
                self.refreshDownloaded()
                if !localFiles(s.name).isEmpty { self.enable(s, volume: volume) }
            }
        }.resume()
    }
}

/// ditto reads the zip format Apple ships these in; Foundation has no unzip.
func unpack(_ tmp: URL, into name: String) {
    let dest = cacheDir.appendingPathComponent(name)
    try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
    let zip = tmp.appendingPathExtension("zip")
    try? FileManager.default.moveItem(at: tmp, to: zip)
    let unzipped = dest.appendingPathComponent("_x")
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
    p.arguments = ["-x", "-k", zip.path, unzipped.path]
    try? p.run()
    p.waitUntilExit()
    for f in m4as(in: unzipped.appendingPathComponent("AssetData")) {
        try? FileManager.default.moveItem(at: f, to: dest.appendingPathComponent(f.lastPathComponent))
    }
    try? FileManager.default.removeItem(at: unzipped)
    try? FileManager.default.removeItem(at: zip)
}

extension Mixer: URLSessionDownloadDelegate {
    nonisolated func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo _: URL) {}
    nonisolated func urlSession(_: URLSession, downloadTask task: URLSessionDownloadTask,
                                didWriteData _: Int64, totalBytesWritten written: Int64,
                                totalBytesExpectedToWrite total: Int64) {
        guard total > 0, let name = task.originalRequest?.url?.lastPathComponent else { return }
        let pct = Double(written) / Double(total)
        Task { @MainActor in
            if let s = self.catalog.first(where: { $0.url.lastPathComponent == name }) { self.progress[s.name] = pct }
        }
    }
}

// MARK: - UI

struct Tile: View {
    let sound: Sound
    @ObservedObject var mixer: Mixer

    var body: some View {
        let on = mixer.isOn(sound.name)
        let pct = mixer.progress[sound.name]
        VStack(spacing: 3) {
            ZStack {
                Image(systemName: sound.symbol)
                    .font(.system(size: 14))
                    .opacity(pct == nil ? 1 : 0.25)
                if let pct {
                    Text("\(Int(pct * 100))%").font(.system(size: 9, weight: .medium))
                }
            }
            .frame(height: 19)

            Text(sound.name).font(.system(size: 9)).lineLimit(1)

            if on {
                Slider(value: Binding(get: { mixer.mix[sound.name] ?? 0.8 },
                                      set: { mixer.setVolume(sound.name, $0) }), in: 0 ... 1)
                    .controlSize(.mini)
            } else {
                Text(mixer.downloaded.contains(sound.name) ? " " : "\(sound.bytes / 1_000_000) MB")
                    .font(.system(size: 8)).foregroundStyle(.secondary)
            }
        }
        .frame(height: 50)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(on ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture { mixer.toggle(sound) }
    }
}
struct Presets: View {
    @ObservedObject var mixer: Mixer
    /// nil while typing a new preset's name; set to the one being renamed otherwise.
    @State private var renaming: String?
    @State private var typing = false
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(mixer.presets) { preset in
                        Text(preset.name)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(Capsule().fill(Color.primary.opacity(preset.builtin ? 0.08 : 0.16)))
                            .contentShape(Capsule())
                            .onTapGesture { mixer.apply(preset) }
                            .contextMenu { menu(for: preset) }
                    }
                    Button { startTyping(renaming: nil) } label: {
                        Image(systemName: "plus.circle").font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .disabled(mixer.mix.isEmpty)
                    .help("Save the current mix as a preset")
                }
                .padding(.horizontal, 1)
            }

            if typing {
                TextField(renaming == nil ? "Preset name" : "Rename preset", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
                    .onSubmit(commit)
                    .onExitCommand { typing = false }
            }
        }
    }

    @ViewBuilder
    private func menu(for preset: Preset) -> some View {
        // A built-in cannot be edited in place, but the current mix can be saved beside it.
        if preset.builtin {
            Button("Save Current Mix as New...") { startTyping(renaming: nil) }
                .disabled(mixer.mix.isEmpty)
        } else {
            Button("Update to Current Mix") { mixer.savePreset(preset.name) }
                .disabled(mixer.mix.isEmpty)
            Button("Rename...") { startTyping(renaming: preset.name) }
            Divider()
            Button("Delete") { mixer.deletePreset(preset.name) }
        }
    }

    private func startTyping(renaming name: String?) {
        renaming = name
        draft = name ?? ""
        typing = true
    }

    private func commit() {
        if let old = renaming { mixer.renamePreset(old, to: draft) } else { mixer.savePreset(draft) }
        draft = ""
        renaming = nil
        typing = false
    }
}

struct Panel: View {
    @ObservedObject var mixer: Mixer

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill").font(.system(size: 11)).foregroundStyle(.secondary)
                Slider(value: Binding(get: { mixer.master }, set: { mixer.setMaster($0) }), in: 0 ... 1)
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 11)).foregroundStyle(.secondary)
            }

            Presets(mixer: mixer)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 4), spacing: 5) {
                ForEach(mixer.catalog) { Tile(sound: $0, mixer: mixer) }
            }

            HStack {
                Menu(mixer.muteAt == nil ? "Timer" : "Muting \(mixer.muteAt!, style: .relative)") {
                    Button("Off") { mixer.mute(after: nil) }
                    Button("30 minutes") { mixer.mute(after: 30) }
                    Button("1 hour") { mixer.mute(after: 60) }
                }
                .menuStyle(.borderlessButton).fixedSize()

                Spacer()
                Button("Stop all") { mixer.stopAll() }.disabled(mixer.mix.isEmpty)
                Menu {
                    Toggle("Open at Login", isOn: Binding(get: { mixer.atLogin }, set: { mixer.setLogin($0) }))
                    Divider()
                    Button("Quit") { NSApp.terminate(nil) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            }
            .font(.system(size: 11))
        }
        .padding(12)
        .frame(width: 320)
    }
}

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

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let mixer = Mixer()
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var playing: Bool?

    func applicationDidFinishLaunching(_: Notification) {
        replaceOtherInstances()
        popover.behavior = .transient
        let host = NSHostingController(rootView: Panel(mixer: mixer))
        // Without this the popover keeps its own default size and clips the panel's top padding.
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        item.button?.target = self
        item.button?.action = #selector(toggle)
        mixer.onPlayingChange = { [weak self] in self?.refreshIcon() }
        refreshIcon()
    }

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

    @objc private func toggle() {
        guard let button = item.button else { return }
        if popover.isShown { return popover.performClose(nil) }
        NSApp.activate()
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func refreshIcon() {
        guard let button = item.button else { return }
        let isPlaying = !mixer.mix.isEmpty
        guard isPlaying != playing else { return }
        playing = isPlaying

        button.layer?.sublayers?.filter { $0.name == "eq" }.forEach { $0.removeFromSuperlayer() }
        if isPlaying {
            // Without an image a variable-length item collapses and clips the layers.
            item.length = barsItemLength
            installBars(on: button)
        } else {
            item.length = NSStatusItem.variableLength
            button.image = NSImage(systemSymbolName: "water.waves.slash", accessibilityDescription: "Sounds")
        }
    }
}

/// Self-check: no window server needed, proves catalog parse + local lookup.
@MainActor
func check() {
    let mixer = Mixer()
    let deadline = Date().addingTimeInterval(20)
    while mixer.catalog.isEmpty, Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
    precondition(mixer.catalog.count == 16, "expected 16 sounds, got \(mixer.catalog.count)")

    // A typo in a preset's sound name is invisible at runtime: the sound is just skipped.
    for preset in Preset.builtin {
        for (name, volume) in preset.mix {
            precondition(mixer.catalog.contains { $0.name == name }, "\(preset.name) references unknown \(name)")
            precondition(volume > 0 && volume <= 1, "\(preset.name)/\(name) volume out of range")
        }
    }

    let saved = mixer.mix
    mixer.mix = ["Rain": 0.5]
    mixer.savePreset("__selfcheck")
    precondition(mixer.presets.contains { $0.name == "__selfcheck" }, "savePreset did not round-trip")

    mixer.mix = ["Ocean": 0.9]
    mixer.savePreset("__selfcheck")
    let updated = mixer.presets.first { $0.name == "__selfcheck" }?.mix
    precondition(updated?.count == 1 && updated?["Ocean"] == 0.9, "update left the old mix behind: \(updated ?? [:])")

    mixer.renamePreset("__selfcheck", to: "__renamed")
    precondition(mixer.presets.contains { $0.name == "__renamed" }, "rename did not create the new name")
    precondition(!mixer.presets.contains { $0.name == "__selfcheck" }, "rename left the old name behind")

    mixer.renamePreset("__renamed", to: "Deep Work")
    precondition(mixer.presets.contains { $0.name == "__renamed" }, "rename onto a built-in name must be refused")

    mixer.deletePreset("__renamed")
    precondition(!mixer.presets.contains { $0.name == "__renamed" }, "deletePreset left a row behind")
    mixer.mix = saved
    print("presets: \(Preset.builtin.map(\.name).joined(separator: ", "))\n")
    for s in mixer.catalog {
        let n = localFiles(s.name).count
        print("\(s.name.padding(toLength: 12, withPad: " ", startingAt: 0)) \(s.bytes / 1_000_000) MB  "
            + (n > 0 ? "installed (\(n))" : "not downloaded") + "  symbol: \(s.symbol)")
    }
}

@main
enum Entry {
    static func main() {
        if CommandLine.arguments.contains("--list") { return MainActor.assumeIsolated { check() } }
        let app = NSApplication.shared
        let delegate = MainActor.assumeIsolated { AppDelegate() }
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
