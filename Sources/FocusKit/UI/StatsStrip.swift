import SwiftUI

/// Seven bars and a total. Enough to answer "how am I doing this week" without a
/// charting dependency, and it costs one UserDefaults read per panel open.
struct StatsStrip: View {
    let today: Double

    /// The bars are sized in the same units as the day letters under them, so the strip
    /// grows with the system text size instead of the letters overrunning a fixed box.
    @ScaledMetric(relativeTo: .caption2) private var barHeight: CGFloat = 18

    private static let letter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEEE")
        return f
    }()

    private var days: [(day: Date, seconds: Double)] {
        FocusStats.lastDays(7, from: FocusStats.load())
    }

    var body: some View {
        let data = days
        let peak = max(data.map(\.seconds).max() ?? 0, 1)
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("Today").font(.footnote).foregroundStyle(.secondary)
                Spacer()
                Text(shortDuration(today)).font(.footnote.weight(.medium))
            }
            if data.allSatisfy({ $0.seconds == 0 }) {
                // Seven stub bars read as a broken chart rather than as an empty one.
                Text("No focus time yet this week")
                    .font(.footnote).foregroundStyle(.tertiary)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(data.indices, id: \.self) { i in
                        let entry = data[i]
                        let isToday = i == data.count - 1
                        VStack(spacing: 2) {
                            Capsule()
                                .fill(Palette.accent.opacity(entry.seconds > 0 ? 0.7 : 0.18))
                                .frame(width: 10, height: max(3, barHeight * entry.seconds / peak))
                            Text(Self.letter.string(from: entry.day))
                                .font(isToday ? .caption2.weight(.bold) : .caption2)
                                .foregroundStyle(isToday ? Color.primary : Color.secondary)
                        }
                        .help("\(FocusStats.dayKey(entry.day)): \(shortDuration(entry.seconds))")
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focused \(shortDuration(today)) today")
    }
}
