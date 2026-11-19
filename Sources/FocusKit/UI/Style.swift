import SwiftUI

/// Tiles and chips had drifted into two opacity scales for the same three states —
/// 0.05/0.10/0.18 against 0.08/0.16/0.30. This is the one scale.
enum Surface {
    static func fill(on: Bool, hovering: Bool = false, raised: Bool = false) -> Color {
        on ? Color.accentColor.opacity(hovering ? 0.28 : 0.22)
           : Color.primary.opacity((raised ? 0.14 : 0.07) + (hovering ? 0.06 : 0))
    }
}

extension View {
    /// Padding, shape and hit area of a pill in the panel. `fill` nil draws the dashed
    /// outline the "save a preset" chip uses to read as an empty slot.
    func chipShape(fill: Color?) -> some View {
        padding(.horizontal, 12).padding(.vertical, 7)
            .background {
                if let fill { Capsule().fill(fill) }
                else {
                    Capsule().strokeBorder(Color.primary.opacity(0.25),
                                           style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                }
            }
            .contentShape(Capsule())
    }
}

/// The tiles and the preset chips were bare tap gestures, so the two things people click
/// most were the only two that never answered the pointer. Hover lives here, not in each
/// caller's `@State`, which is what kept the two surfaces' fills out of step.
struct PanelButton<S: InsettableShape>: ButtonStyle {
    let shape: S
    var insets = EdgeInsets(top: 7, leading: 12, bottom: 7, trailing: 12)
    var on = false
    var raised = false
    var dashed = false

    func makeBody(configuration: Configuration) -> some View {
        Pill(shape: shape, insets: insets, on: on, raised: raised, dashed: dashed,
             pressed: configuration.isPressed, label: configuration.label)
    }

    private struct Pill: View {
        let shape: S
        let insets: EdgeInsets
        let on, raised, dashed: Bool
        let pressed: Bool
        let label: Configuration.Label
        @State private var hovering = false

        var body: some View {
            label
                .padding(insets)
                .background {
                    if dashed {
                        shape.strokeBorder(Color.primary.opacity(0.25),
                                           style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                    } else {
                        shape.fill(Surface.fill(on: on, hovering: hovering, raised: raised))
                    }
                }
                .contentShape(shape)
                .scaleEffect(pressed ? 0.96 : (hovering ? 1.02 : 1))
                .animation(.easeOut(duration: 0.12), value: pressed)
                .animation(.easeOut(duration: 0.12), value: hovering)
                .onHover { hovering = $0 }
        }
    }
}
