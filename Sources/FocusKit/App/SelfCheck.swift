import AppKit

/// Smoke check behind `--list`: needs the network and a writable cache, so it stays a
/// CLI path rather than an XCTest. The pure logic is covered by `swift test`.
@MainActor
public func selfCheck() {
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

    mixer.renamePreset("__renamed", to: "Coding & Logic")
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
