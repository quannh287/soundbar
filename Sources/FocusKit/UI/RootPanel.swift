import SwiftUI

public struct RootPanel: View {
    @ObservedObject var mixer: Mixer
    @ObservedObject var session: FocusSession
    @State private var tab = Tab.focus

    enum Tab: String, CaseIterable, Identifiable {
        case focus, sound
        var id: String { rawValue }
    }

    public init(mixer: Mixer, session: FocusSession) {
        self.mixer = mixer
        self.session = session
    }

    public var body: some View {
        VStack(spacing: 10) {
            Picker("", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue.capitalized).tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden()
            .accessibilityLabel("Panel section")

            switch tab {
            case .focus: FocusPanel(session: session, mixer: mixer)
            case .sound: SoundPanel(mixer: mixer)
            }

            Divider()

            HStack(alignment: .bottom, spacing: 10) {
                StatsStrip(today: session.today)
                Menu {
                    Toggle("Open at Login", isOn: Binding(get: { mixer.atLogin },
                                                          set: { mixer.setLogin($0) }))
                    Divider()
                    Button("Quit") { NSApp.terminate(nil) }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel("More options")
                .menuStyle(.borderlessButton).menuIndicator(.hidden).fixedSize()
            }
        }
        .padding(12)
        .frame(width: 320)
    }
}
