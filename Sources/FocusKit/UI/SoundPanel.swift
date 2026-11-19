import SwiftUI

/// The tiles and the preset chips were bare tap gestures, so the two things people click
/// most were the only two that never answered the pointer.
struct CardButton: ButtonStyle {
    let hovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : (hovering ? 1.02 : 1))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct Tile: View {
    let sound: Sound
    @ObservedObject var mixer: Mixer
    @State private var hovering = false

    var body: some View {
        let on = mixer.isOn(sound.name)
        let pct = mixer.progress[sound.name]
        Button { mixer.toggle(sound) } label: { card(on: on, pct: pct) }
            .buttonStyle(CardButton(hovering: hovering))
            .onHover { hovering = $0 }
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
                    .font(.system(size: 14))
                    .opacity(pct == nil ? 1 : 0.25)
                if let pct {
                    Text("\(Int(pct * 100))%").font(.system(size: 9, weight: .medium))
                }
            }
            .frame(height: 19)

            Text(sound.display).font(.system(size: 9)).lineLimit(1).minimumScaleFactor(0.85)

            if on {
                Slider(value: Binding(get: { mixer.mix[sound.name] ?? 0.8 },
                                      set: { mixer.setVolume(sound.name, $0) }), in: 0 ... 1)
                    .controlSize(.mini)
                    .accessibilityLabel("\(sound.display) volume")
            } else {
                // A bare size read as missing data; the arrow says it is a download.
                Text(mixer.downloaded.contains(sound.name)
                    ? " " : "↓ \(sound.bytes / 1_000_000) MB")
                    .font(.system(size: 8)).foregroundStyle(.secondary)
            }
        }
        .frame(height: 50)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(on ? Color.accentColor.opacity(0.18)
                       : Color.primary.opacity(hovering ? 0.10 : 0.05),
                    in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}

struct PresetChip: View {
    let preset: Preset
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Text(preset.name)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Color.primary
                    .opacity((preset.builtin ? 0.08 : 0.16) + (hovering ? 0.08 : 0))))
                .contentShape(Capsule())
        }
        .buttonStyle(CardButton(hovering: hovering))
        .onHover { hovering = $0 }
        .help("Play the \(preset.name) mix")
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

    var body: some View {
        VStack(spacing: 6) {
            FlowLayout(spacing: 6) {
                ForEach(mixer.presets) { preset in
                    PresetChip(preset: preset) { mixer.apply(preset) }
                        .contextMenu { menu(for: preset) }
                }
                Button { startTyping(renaming: nil) } label: {
                    Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().strokeBorder(Color.primary.opacity(0.25),
                                                           style: StrokeStyle(lineWidth: 1, dash: [3, 2])))
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(mixer.mix.isEmpty)
                .accessibilityLabel("Save current mix as a preset")
                .help("Save the current mix as a preset")
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

struct SoundPanel: View {
    @ObservedObject var mixer: Mixer

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "speaker.fill").font(.system(size: 11)).foregroundStyle(.secondary)
                Slider(value: Binding(get: { mixer.master }, set: { mixer.setMaster($0) }), in: 0 ... 1)
                    .accessibilityLabel("Master volume")
                Image(systemName: "speaker.wave.3.fill").font(.system(size: 11)).foregroundStyle(.secondary)
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
                .menuStyle(.borderlessButton).fixedSize().font(.system(size: 11))
                Spacer()
                Button("Stop sounds") { mixer.stopAll() }.disabled(mixer.mix.isEmpty)
            }
            .font(.system(size: 11))
        }
    }
}
