import SwiftUI

struct FocusPanel: View {
    @ObservedObject var session: FocusSession
    @ObservedObject var mixer: Mixer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if session.running { active } else { setup }
        }
    }

    // MARK: before

    private var setup: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 6) {
                Picker("", selection: Binding(get: { session.candidate?.id ?? 0 },
                                              set: { id in
                    session.candidate = session.candidates.first { $0.id == id }?.window
                })) {
                    if session.candidates.isEmpty { Text("No window").tag(CGWindowID(0)) }
                    ForEach(session.candidates) { Text($0.label).tag($0.id) }
                }
                .labelsHidden()
                .accessibilityLabel("Window to focus")
            }

            HStack(spacing: 8) {
                Picker("", selection: $session.minutes) {
                    ForEach([15, 25, 45, 60], id: \.self) { Text("\($0)m").tag($0) }
                }
                .labelsHidden().fixedSize()
                .accessibilityLabel("Session length")

                Picker("", selection: Binding(get: { session.presetName ?? "" },
                                              set: { session.presetName = $0.isEmpty ? nil : $0 })) {
                    Text("Keep mix").tag("")
                    ForEach(mixer.presets) { Text($0.name).tag($0.name) }
                }
                .labelsHidden()
                .accessibilityLabel("Sound to play")
            }

            effects

            HStack(spacing: 8) {
                Toggle("Shake when I drift", isOn: Binding(get: { session.nudgeGrace > 0 },
                                                          set: { session.nudgeGrace = $0 ? 5 : 0 }))
                    .toggleStyle(.checkbox)
                if session.nudgeGrace > 0 {
                    Picker("", selection: $session.nudgeGrace) {
                        Text("after 5s").tag(5.0)
                        Text("after 15s").tag(15.0)
                        Text("after 30s").tag(30.0)
                    }
                    .labelsHidden().fixedSize()
                    .accessibilityLabel("Wait before shaking")
                }
            }
            .font(.subheadline)

            Toggle("Full screen while focusing", isOn: $session.fullScreen)
                .toggleStyle(.checkbox)
                .font(.subheadline)

            Toggle("Pomodoro — break, then another block", isOn: $session.pomodoro)
                .toggleStyle(.checkbox)
                .font(.subheadline)

            // The width has to go on the label: a bordered button sizes to its content.
            Button { session.start() } label: {
                Text("Start Focus").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .onChange(of: session.nudgeGrace) { _ in session.persist() }
        .onChange(of: session.minutes) { _ in session.persist() }
        .onChange(of: session.pomodoro) { _ in session.persist() }
        .onChange(of: session.fullScreen) { _ in
            session.persist()
            session.requestFullScreenAccess()
        }
    }

    /// A plain menu, not a second segmented control: the tab picker above is the panel's
    /// top-level navigation, and two identical-looking segmented rows flattened it.
    private var effects: some View {
        HStack(spacing: 8) {
            Picker("", selection: $session.mode) {
                ForEach(FocusMode.allCases) { Text($0.label).tag($0) }
            }
            .labelsHidden().fixedSize()
            .accessibilityLabel("Effect")
            .onChange(of: session.mode) { _ in session.applyAppearance() }

            Slider(value: $session.intensity, in: 0.2 ... 0.95)
                .accessibilityLabel("Effect strength")
                .onChange(of: session.intensity) { _ in session.applyIntensity() }
        }
    }

    // MARK: during

    private var active: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(header).font(.headline)
                Spacer()
                if session.onBreak { Button("Skip break") { session.skipBreak() } }
                // Not "Stop": the Sound tab has its own Stop, and these end different things.
                Button("End focus") { session.stop() }
            }

            if session.onBreak {
                Text("Block \(session.round) done. The next one starts on its own.")
                    .font(.footnote).foregroundStyle(.secondary)
            }

            if session.lostTargets {
                Label("Pinned window is gone", systemImage: "exclamationmark.triangle")
                    .font(.footnote).foregroundStyle(Palette.warning)
            }

            if session.fullScreenBlocked {
                Label("Full screen needs SoundBar under Privacy › Accessibility.",
                      systemImage: "exclamationmark.triangle")
                    .font(.footnote).foregroundStyle(Palette.warning)
            }

            if !session.onBreak { working }
        }
    }

    private var header: String {
        let left = session.remainingLabel
        if session.onBreak { return left.isEmpty ? "Break" : "Break — \(left) left" }
        return left.isEmpty ? "Focusing" : left + " left"
    }

    @ViewBuilder private var working: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(session.targets, id: \.id) { target in
                HStack(spacing: 5) {
                    Image(systemName: "macwindow").font(.footnote)
                    Text(target.label).font(.subheadline).lineLimit(1)
                    Spacer()
                    if session.targets.count > 1 {
                        Button { session.drop(target.id) } label: {
                            Image(systemName: "xmark.circle.fill").font(.footnote)
                        }
                        .buttonStyle(.plain).foregroundStyle(.secondary)
                    }
                }
            }

            effects

            HStack(spacing: 8) {
                Menu("Add window") {
                    ForEach(session.candidates.filter { choice in
                        !session.targets.contains { $0.id == choice.id }
                    }) { choice in
                        Button(choice.label) { session.add(choice.window) }
                    }
                }
                .menuStyle(.borderlessButton).fixedSize()
                Button("Peek 10s") { session.peek() }
                Spacer()
            }
            .font(.subheadline)
        }
    }
}
