import SwiftUI

struct Tile: View {
    let sound: Sound
    @ObservedObject var mixer: Mixer

    var body: some View {
        let on = mixer.isOn(sound.name)
        let pct = mixer.progress[sound.name]
        Button { mixer.toggle(sound) } label: { card(on: on, pct: pct) }
            .buttonStyle(PanelButton(shape: RoundedRectangle(cornerRadius: 8),
                                     insets: EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0),
                                     on: on))
            .accessibilityLabel(sound.display)
            .accessibilityValue(on ? "on" : "off")
            .accessibilityAddTraits(on ? [.isSelected] : [])
            .help(mixer.downloaded.contains(sound.name)
                ? (on ? "Turn \(sound.display) off" : "Turn \(sound.display) on")
                : "Download \(sound.display), \(sound.bytes / 1_000_000) MB")
    }

    private func card(on: Bool, pct: Double?) -> some View {
        VStack(spacing: 3) {
            ZStack {
                Image(systemName: sound.symbol)
                    .font(.body)
                    .opacity(pct == nil ? 1 : 0.25)
                if let pct {
                    Text("\(Int(pct * 100))%").font(.caption.weight(.medium))
                }
            }
            .frame(height: 19)

            Text(sound.display).font(.caption).lineLimit(1).minimumScaleFactor(0.85)

            if on {
                Slider(value: Binding(get: { mixer.mix[sound.name] ?? 0.8 },
                                      set: { mixer.setVolume(sound.name, $0) }), in: 0 ... 1)
                    .controlSize(.mini)
                    .accessibilityLabel("\(sound.display) volume")
            } else {
                // A bare size read as missing data; the arrow says it is a download.
                Text(mixer.downloaded.contains(sound.name)
                    ? " " : "↓ \(sound.bytes / 1_000_000) MB")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
    }
}

struct PresetChip: View {
    let preset: Preset
    var active = false
    var suggested = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(preset.name).font(.callout.weight(.medium))
        }
        .buttonStyle(PanelButton(shape: Capsule(), on: active, raised: !preset.builtin))
        .overlay { if suggested, !active { Capsule().strokeBorder(Palette.accent.opacity(0.45)) } }
        .help(suggested ? "Play the \(preset.name) mix — suits the hour"
                        : "Play the \(preset.name) mix")
    }
}
/// Chips wrap instead of scrolling. A horizontal ScrollView needs a horizontal gesture
/// a mouse wheel cannot give, and a 320pt popover has no room for a scrollbar to drag —
/// so the `+` chip at the end was simply unreachable.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let limit = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, row: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > limit {
                x = 0
                y += row + spacing
                row = 0
            }
            x += size.width + spacing
            row = max(row, size.height)
        }
        return CGSize(width: limit.isFinite ? limit : x, height: y + row)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize,
                       subviews: Subviews, cache _: inout ()) {
        var x = bounds.minX, y = bounds.minY, row: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += row + spacing
                row = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            row = max(row, size.height)
        }
    }
}

struct Presets: View {
    @ObservedObject var mixer: Mixer
    /// nil while typing a new preset's name; set to the one being renamed otherwise.
    @State private var renaming: String?
    @State private var typing = false
    @State private var draft = ""
    private let hint = Preset.suggested()

    var body: some View {
        VStack(spacing: 6) {
            FlowLayout(spacing: 6) {
                Menu {
                    if mixer.autoEvery != nil { Button("Stop rotating") { mixer.setAuto(nil) } }
                    Button("Shuffle now") { mixer.shuffle() }
                    Divider()
                    ForEach([5, 15, 30, 60], id: \.self) { minutes in
                        Button(minutes == 60 ? "Rotate every hour"
                                             : "Rotate every \(minutes) minutes") {
                            mixer.setAuto(minutes)
                        }
                    }
                } label: {
                    Label(mixer.autoEvery.map { "Auto · \($0)m" } ?? "Auto", systemImage: "shuffle")
                        .font(.callout.weight(.medium))
                }
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
                .chipShape(fill: Surface.fill(on: mixer.autoEvery != nil))
                .disabled(!mixer.canAuto)
                .help(mixer.canAuto
                    ? "Play a random pairing and change it on a timer"
                    : "Download a sound first")

                ForEach(mixer.presets) { preset in
                    PresetChip(preset: preset, active: mixer.mix == preset.mix,
                               suggested: preset.name == hint) { mixer.apply(preset) }
                        .contextMenu { menu(for: preset) }
                }
                Button { startTyping(renaming: nil) } label: {
                    Image(systemName: "plus").font(.subheadline.weight(.semibold))
                }
                .buttonStyle(PanelButton(shape: Capsule(), dashed: true))
                .disabled(mixer.mix.isEmpty)
                .accessibilityLabel("Save current mix as a preset")
                .help("Save the current mix as a preset")
            }

            if typing {
                TextField(renaming == nil ? "Preset name" : "Rename preset", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
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

struct SoundPanel: View {
    @ObservedObject var mixer: Mixer

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill").font(.subheadline).foregroundStyle(.secondary)
                Slider(value: Binding(get: { mixer.master }, set: { mixer.setMaster($0) }), in: 0 ... 1)
                    .accessibilityLabel("Master volume")
                Image(systemName: "speaker.wave.3.fill").font(.subheadline).foregroundStyle(.secondary)
            }

            Presets(mixer: mixer)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 4), spacing: 5) {
                ForEach(mixer.catalog) { Tile(sound: $0, mixer: mixer) }
            }

            HStack {
                // Named for what it mutes: the focus timer is a different clock in the
                // same panel, and "Timer" alone did not say which one this was.
                Menu(mixer.muteAt == nil ? "Mute after"
                                         : "Muting \(mixer.muteAt!, style: .relative)") {
                    Button("Off") { mixer.mute(after: nil) }
                    Button("30 minutes") { mixer.mute(after: 30) }
                    Button("1 hour") { mixer.mute(after: 60) }
                }
                .menuStyle(.borderlessButton).fixedSize().font(.subheadline)
                Spacer()
                Button("Stop sounds") { mixer.stopAll() }.disabled(mixer.mix.isEmpty)
            }
            .font(.subheadline)
        }
    }
}
