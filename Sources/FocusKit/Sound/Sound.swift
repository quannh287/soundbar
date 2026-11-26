import AppKit

let catalogURL = URL(string: "https://mesu.apple.com/assets/macos/com_apple_MobileAsset_ComfortSoundsAssets/com_apple_MobileAsset_ComfortSoundsAssets.xml")!
let systemAssets = URL(fileURLWithPath: "/System/Library/AssetsV2/com_apple_MobileAsset_ComfortSoundsAssets")
let cacheDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("SoundBar")

public struct Sound: Identifiable, Hashable, Sendable {
    public let name: String
    let url: URL
    let bytes: Int
    public var id: String { name }

    /// "RainOnRoof" is Apple's asset identifier, not a label. The stored name stays the
    /// key every preset and UserDefaults entry is written against.
    public var display: String {
        name.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2",
                                  options: .regularExpression)
    }

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

public struct Preset: Identifiable, Hashable {
    public let name: String
    let mix: [String: Float]
    var builtin = false
    public var id: String { name }

    /// One deep bed plus one or two lighter layers, never more than three: past that the
    /// layers mask each other and the mix tires the ear.
    public static let builtin: [Preset] = [
        // Work & study
        Preset(name: "Coding & Logic", mix: ["BrownNoise": 0.5, "Train": 0.2, "Stream": 0.15], builtin: true),
        Preset(name: "Reading & Study", mix: ["PinkNoise": 0.35, "RainOnRoof": 0.25, "QuietNight": 0.15], builtin: true),
        Preset(name: "Brainstorming", mix: ["Ocean": 0.35, "Babble": 0.2, "Steam": 0.15], builtin: true),
        Preset(name: "Noisy Room Masker", mix: ["WhiteNoise": 0.35, "PinkNoise": 0.35, "Rain": 0.25], builtin: true),
        // Relax
        Preset(name: "Rainy Cabin", mix: ["RainOnRoof": 0.45, "Fire": 0.3, "BrownNoise": 0.2], builtin: true),
        Preset(name: "Coastal Breeze", mix: ["Ocean": 0.45, "Boat": 0.15, "Night": 0.15], builtin: true),
        Preset(name: "Forest Creek", mix: ["Stream": 0.45, "Night": 0.25, "PinkNoise": 0.15], builtin: true),
        Preset(name: "Slow Sunday", mix: ["Babble": 0.2, "Stream": 0.25, "Fire": 0.2], builtin: true),
        // Sleep
        Preset(name: "Power Nap", mix: ["BrownNoise": 0.55, "Rain": 0.25], builtin: true),
        Preset(name: "Deep Insomnia", mix: ["BrownNoise": 0.45, "QuietNight": 0.35, "Ocean": 0.2], builtin: true),
        Preset(name: "Night Train Lullaby", mix: ["Train": 0.3, "BrownNoise": 0.35, "QuietNight": 0.2], builtin: true),
        // Travel
        Preset(name: "Long Bus Ride", mix: ["Bus": 0.4, "BrownNoise": 0.3, "Rain": 0.15], builtin: true),
        Preset(name: "Harbor & Ferry", mix: ["Boat": 0.35, "Ocean": 0.35, "Stream": 0.15], builtin: true),
    ]

    /// The built-in the clock points at. A hint the panel tints only — nothing auto-applies,
    /// because a mix that changes itself while you work is the thing people disable first.
    public static func suggested(at date: Date = Date()) -> String {
        switch Calendar.current.component(.hour, from: date) {
        case 6 ..< 9: return "Slow Sunday"
        case 9 ..< 18: return "Coding & Logic"
        case 18 ..< 22: return "Rainy Cabin"
        default: return "Deep Insomnia"
        }
    }

    /// Auto mode deals the same shape the built-ins have rather than picking at random:
    /// a bed is broad enough to sit under something, a texture is sparse enough to sit on
    /// top, and two of either kind at once just fight each other.
    static let beds = ["BrownNoise", "PinkNoise", "WhiteNoise", "Ocean", "Fire",
                       "Airplane", "Bus", "Train", "Boat", "Babble"]
    static let textures = ["Rain", "RainOnRoof", "Stream", "Night", "QuietNight", "Steam"]

    /// `available` is what is already on disk: a rotation must never start a download.
    /// Returns nil when nothing playable is left, and avoids dealing `current` again.
    public static func deal(from available: Set<String>,
                            avoiding current: [String: Float]) -> [String: Float]? {
        let beds = Self.beds.filter(available.contains)
        let textures = Self.textures.filter(available.contains)
        guard !beds.isEmpty else { return nil }

        for _ in 0 ..< 8 {
            var next: [String: Float] = [:]
            next[beds.randomElement()!] = Float.random(in: 0.5 ... 0.7)
            if let texture = textures.randomElement(), Bool.random() || textures.count > 1 {
                next[texture] = Float.random(in: 0.25 ... 0.4)
            }
            if Set(next.keys) != Set(current.keys) { return next }
        }
        return nil
    }
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

public func localFiles(_ name: String) -> [URL] {
    let own = m4as(in: cacheDir.appendingPathComponent(name))
    return own.isEmpty ? installedFiles(name) : own
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
