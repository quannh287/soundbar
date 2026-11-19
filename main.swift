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

/// One sound on endless shuffle. Apple ships each as interchangeable variations;
/// shuffling them avoids an audible loop point.
final class Loop {
    private let player = AVQueuePlayer()
    private let files: [URL]
    private var token: NSObjectProtocol?

    init?(_ name: String, volume: Float, master: Float) {
        files = localFiles(name)
        guard !files.isEmpty else { return nil }
        player.volume = volume * master
        token = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main
        ) { [weak self] _ in self?.fill() }
        fill()
        player.play()
    }

    deinit {
        player.pause()
        if let token { NotificationCenter.default.removeObserver(token) }
    }

    func setVolume(_ v: Float) { player.volume = v }

    private func fill() {
        while player.items().count < 2, let f = files.shuffled().first {
            player.insert(AVPlayerItem(url: f), after: nil)
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
    @Published var beat = 0
    @Published var userPresets: [Preset] = []

    var presets: [Preset] { Preset.builtin + userPresets }

    private var loops: [String: Loop] = [:]
    private var timer: Timer?
    private var beatTimer: Timer?

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
        loops[s.name] = nil
        persist()
    }

    fileprivate func enable(_ s: Sound, volume: Float) {
        guard !localFiles(s.name).isEmpty else { return download(s, volume: volume) }
        mix[s.name] = volume
        loops[s.name] = Loop(s.name, volume: volume, master: master)
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

    func deletePreset(_ name: String) {
        var stored = UserDefaults.standard.dictionary(forKey: "presets") as? [String: [String: Double]] ?? [:]
        stored[name] = nil
        UserDefaults.standard.set(stored, forKey: "presets")
        loadPresets()
    }

    private func loadPresets() {
        let stored = UserDefaults.standard.dictionary(forKey: "presets") as? [String: [String: Double]] ?? [:]
        userPresets = stored.keys.sorted().map { Preset(name: $0, mix: stored[$0]!.mapValues { Float($0) }) }
    }

    func setVolume(_ name: String, _ v: Float) {
        mix[name] = v
        loops[name]?.setVolume(v * master)
        persist()
    }

    func setMaster(_ v: Float) {
        master = v
        for (name, vol) in mix { loops[name]?.setVolume(vol * v) }
        persist()
    }

    /// Restart whatever was playing when the app last quit.
    private func resume() {
        for (name, vol) in mix where loops[name] == nil {
            loops[name] = Loop(name, volume: vol, master: master)
        }
        syncBeat()
    }

    func stopAll() {
        loops.removeAll()
        mix.removeAll()
        muteAt = nil
        timer?.invalidate()
        persist()
    }

    /// Only tick while something plays; an idle menu bar should not wake the CPU 4x a second.
    private func syncBeat() {
        guard mix.isEmpty == (beatTimer != nil) else { return }
        beatTimer?.invalidate()
        beatTimer = mix.isEmpty ? nil : Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            Task { @MainActor in self.beat &+= 1 }
        }
    }

    private func persist() {
        syncBeat()
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
        VStack(spacing: 4) {
            ZStack {
                Image(systemName: sound.symbol)
                    .font(.system(size: 18))
                    .opacity(pct == nil ? 1 : 0.25)
                if let pct {
                    Text("\(Int(pct * 100))%").font(.system(size: 10, weight: .medium))
                }
            }
            .frame(height: 24)

            Text(sound.name).font(.system(size: 10)).lineLimit(1)

            if on {
                Slider(value: Binding(get: { mixer.mix[sound.name] ?? 0.8 },
                                      set: { mixer.setVolume(sound.name, $0) }), in: 0 ... 1)
                    .controlSize(.mini)
            } else {
                Text(localFiles(sound.name).isEmpty ? "\(sound.bytes / 1_000_000) MB" : " ")
                    .font(.system(size: 9)).foregroundStyle(.secondary)
            }
        }
        .frame(height: 68)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(on ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture { mixer.toggle(sound) }
    }
}

/// A MenuBarExtra label only renders Text and Image, and never runs SwiftUI animations
/// or SF Symbol effects — so the bars are drawn into template images and stepped by a timer.
enum Bars {
    private static let frames: [[CGFloat]] = [[0.35, 1.0, 0.6], [1.0, 0.5, 0.85],
                                              [0.6, 0.8, 0.4], [0.85, 0.45, 1.0]]

    static let images: [NSImage] = frames.map { heights in
        let size = NSSize(width: 15, height: 16)
        let image = NSImage(size: size, flipped: false) { _ in
            NSColor.black.setFill()
            for (i, f) in heights.enumerated() {
                let h = 13 * f
                let bar = NSRect(x: CGFloat(i) * 5.5, y: (size.height - h) / 2, width: 3, height: h)
                NSBezierPath(roundedRect: bar, xRadius: 1.5, yRadius: 1.5).fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }

    static func image(_ beat: Int) -> NSImage { images[beat % images.count] }
}

struct Presets: View {
    @ObservedObject var mixer: Mixer
    @State private var naming = false
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(mixer.presets) { preset in
                        Text(preset.name)
                            .font(.system(size: 10))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Capsule().fill(Color.primary.opacity(preset.builtin ? 0.08 : 0.16)))
                            .contentShape(Capsule())
                            .onTapGesture { mixer.apply(preset) }
                            .contextMenu {
                                if !preset.builtin {
                                    Button("Delete") { mixer.deletePreset(preset.name) }
                                }
                            }
                    }
                    Button { naming.toggle() } label: { Image(systemName: "plus.circle") }
                        .buttonStyle(.plain)
                        .disabled(mixer.mix.isEmpty)
                        .help("Save the current mix as a preset")
                }
                .padding(.horizontal, 1)
            }

            if naming {
                TextField("Preset name", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 11))
                    .onSubmit {
                        mixer.savePreset(draft)
                        draft = ""
                        naming = false
                    }
            }
        }
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

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
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

struct SoundBarApp: App {
    @StateObject private var mixer = Mixer()

    var body: some Scene {
        MenuBarExtra {
            Panel(mixer: mixer)
        } label: {
            if mixer.mix.isEmpty {
                Image(systemName: "water.waves.slash")
            } else {
                Image(nsImage: Bars.image(mixer.beat))
            }
        }
        .menuBarExtraStyle(.window)
    }
}

/// Self-check: no window server needed, proves catalog parse + local lookup.
@MainActor
func check() {
    let mixer = Mixer()
    let deadline = Date().addingTimeInterval(20)
    while mixer.catalog.isEmpty, Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.1)) }
    assert(mixer.catalog.count == 16, "expected 16 sounds, got \(mixer.catalog.count)")

    // A typo in a preset's sound name is invisible at runtime: the sound is just skipped.
    for preset in Preset.builtin {
        for (name, volume) in preset.mix {
            assert(mixer.catalog.contains { $0.name == name }, "\(preset.name) references unknown \(name)")
            assert(volume > 0 && volume <= 1, "\(preset.name)/\(name) volume out of range")
        }
    }

    let saved = mixer.mix
    mixer.mix = ["Rain": 0.5]
    mixer.savePreset("__selfcheck")
    assert(mixer.presets.contains { $0.name == "__selfcheck" }, "savePreset did not round-trip")
    mixer.deletePreset("__selfcheck")
    assert(!mixer.presets.contains { $0.name == "__selfcheck" }, "deletePreset left a row behind")
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
        if CommandLine.arguments.contains("--list") { MainActor.assumeIsolated { check() } }
        else { SoundBarApp.main() }
    }
}
