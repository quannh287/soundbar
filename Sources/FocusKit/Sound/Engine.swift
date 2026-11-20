import AVFoundation

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

    private var fade: Timer?

    /// Swapping the mix outright is a hard cut every rotation, which is exactly the kind
    /// of audible seam the shuffling above exists to avoid. Ramps both directions at once.
    func crossfade(to target: [String: Float], seconds: Double) {
        fade?.invalidate()
        var from: [String: Float] = [:]
        for name in Set(nodes.keys).union(target.keys) {
            from[name] = nodes[name]?.volume ?? 0
            if nodes[name] == nil { add(name, volume: 0) }
        }
        let steps = 30
        var step = 0
        let timer = Timer(timeInterval: seconds / Double(steps), repeats: true) { [weak self] t in
            MainActor.assumeIsolated {
                guard let self else { return t.invalidate() }
                step += 1
                let progress = Float(min(1, Double(step) / Double(steps)))
                for (name, start) in from {
                    let end = target[name] ?? 0
                    self.setVolume(name, start + (end - start) * progress)
                }
                guard step >= steps else { return }
                t.invalidate()
                self.fade = nil
                for name in from.keys where target[name] == nil { self.remove(name) }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        fade = timer
    }

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
