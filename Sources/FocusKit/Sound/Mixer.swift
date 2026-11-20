import AVFoundation
import ServiceManagement
import SwiftUI

@MainActor
public final class Mixer: NSObject, ObservableObject {
    @Published public var catalog: [Sound] = []
    @Published public var mix: [String: Float] = [:]
    @Published public var progress: [String: Double] = [:]
    @Published public var master: Float = UserDefaults.standard.object(forKey: "master") as? Float ?? 0.7
    @Published public var muteAt: Date?
    @Published public var atLogin = SMAppService.mainApp.status == .enabled
    @Published public var downloaded: Set<String> = []
    var onPlayingChange: (() -> Void)?
    @Published public var userPresets: [Preset] = []
    /// Minutes between rotations; nil is off. Persisted, so it survives a relaunch.
    @Published public var autoEvery: Int? = UserDefaults.standard.object(forKey: "autoEvery") as? Int
    @Published public var autoNext: Date?

    public var presets: [Preset] { Preset.builtin + userPresets }

    private let engine = Engine()
    private var timer: Timer?
    private var autoTimer: Timer?

    override public init() {
        super.init()
        if let d = UserDefaults.standard.dictionary(forKey: "mix") as? [String: Double] {
            mix = d.mapValues { Float($0) }
        }
        loadPresets()
        loadCatalog()
    }

    // MARK: catalog

    public func loadCatalog(_ done: (() -> Void)? = nil) {
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

    public func isOn(_ name: String) -> Bool { mix[name] != nil }

    public func toggle(_ s: Sound) {
        // Touching a sound by hand is a decision; the rotation stops arguing with it.
        setAuto(nil)
        guard isOn(s.name) else { return enable(s, volume: 0.8) }
        var next = mix
        next[s.name] = nil
        transition(to: next, seconds: 0.4)
    }

    fileprivate func enable(_ s: Sound, volume: Float) {
        guard !localFiles(s.name).isEmpty else { return download(s, volume: volume) }
        var next = mix
        next[s.name] = volume
        transition(to: next, seconds: 0.4)
    }

    /// Every mix change ramps: a hard cut on an ambient bed is an audible seam, and
    /// AVAudioPlayerNode.stop() clicks on its own.
    private func transition(to target: [String: Float], seconds: Double) {
        engine.master = master
        engine.crossfade(to: target, seconds: seconds)
        mix = target
        persist()
    }

    // MARK: presets

    public func apply(_ preset: Preset) {
        setAuto(nil)
        var target: [String: Float] = [:]
        for (name, volume) in preset.mix {
            guard let s = catalog.first(where: { $0.name == name }) else { continue }
            // Anything not on disk joins the mix later, when its download lands.
            if localFiles(name).isEmpty { download(s, volume: volume) } else { target[name] = volume }
        }
        transition(to: target, seconds: 1.5)
    }

    public func savePreset(_ name: String) {
        let clean = name.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty, !mix.isEmpty, !Preset.builtin.contains(where: { $0.name == clean }) else { return }
        var stored = UserDefaults.standard.dictionary(forKey: "presets") as? [String: [String: Double]] ?? [:]
        stored[clean] = mix.mapValues { Double($0) }
        UserDefaults.standard.set(stored, forKey: "presets")
        loadPresets()
    }

    public func renamePreset(_ old: String, to new: String) {
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

    public func deletePreset(_ name: String) {
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

    public func setVolume(_ name: String, _ v: Float) {
        mix[name] = v
        engine.setVolume(name, v)
        persist()
    }

    public func setMaster(_ v: Float) {
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

    public func stopAll() {
        autoTimer?.invalidate()
        autoTimer = nil
        autoEvery = nil
        autoNext = nil
        muteAt = nil
        timer?.invalidate()
        transition(to: [:], seconds: 0.5)
    }

    private func persist() {
        onPlayingChange?()
        UserDefaults.standard.set(mix.mapValues { Double($0) }, forKey: "mix")
        UserDefaults.standard.set(master, forKey: "master")
    }

    public func setLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("SoundBar: login item \(on ? "register" : "unregister") failed: \(error)")
        }
        // Read back rather than trusting the call: an unsigned or relocated bundle silently stays off.
        atLogin = SMAppService.mainApp.status == .enabled
    }

    // MARK: auto

    public func setAuto(_ minutes: Int?) {
        autoTimer?.invalidate()
        autoTimer = nil
        autoEvery = minutes
        UserDefaults.standard.set(minutes, forKey: "autoEvery")
        guard let minutes else { return autoNext = nil }
        shuffle()
        let timer = Timer(timeInterval: Double(minutes) * 60, repeats: true) { _ in
            MainActor.assumeIsolated { self.shuffle() }
        }
        // .common, or the rotation stalls for as long as any menu is open.
        RunLoop.main.add(timer, forMode: .common)
        autoTimer = timer
    }

    /// Deals from what is already downloaded only — a rotation that started a 60 MB
    /// fetch on its own would be a nasty surprise on a metered connection.
    public func shuffle() {
        guard let next = Preset.deal(from: downloaded, avoiding: mix) else { return }
        transition(to: next, seconds: 2)
        if let autoEvery { autoNext = Date().addingTimeInterval(Double(autoEvery) * 60) }
    }

    public var canAuto: Bool { !Preset.beds.filter(downloaded.contains).isEmpty }

    // MARK: timer

    public func mute(after minutes: Int?) {
        timer?.invalidate()
        guard let minutes else { muteAt = nil; return }
        muteAt = Date().addingTimeInterval(Double(minutes) * 60)
        timer = Timer.scheduledTimer(withTimeInterval: Double(minutes) * 60, repeats: false) { _ in
            Task { @MainActor in self.stopAll() }
        }
    }

    // MARK: download

    public func download(_ s: Sound, volume: Float = 0.8) {
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

extension Mixer: URLSessionDownloadDelegate {
    public nonisolated func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo _: URL) {}
    public nonisolated func urlSession(_: URLSession, downloadTask task: URLSessionDownloadTask,
                                didWriteData _: Int64, totalBytesWritten written: Int64,
                                totalBytesExpectedToWrite total: Int64) {
        guard total > 0, let name = task.originalRequest?.url?.lastPathComponent else { return }
        let pct = Double(written) / Double(total)
        Task { @MainActor in
            if let s = self.catalog.first(where: { $0.url.lastPathComponent == name }) { self.progress[s.name] = pct }
        }
    }
}
