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

    /// Every mix is one deep base plus a lighter layer over it — the shape every
    /// ambient mixer converges on, because two sounds at equal weight fight each other.
    public static let builtin: [Preset] = [
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
