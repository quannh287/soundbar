import SwiftUI

/// Seven bars and a total. Enough to answer "how am I doing this week" without a
/// charting dependency, and it costs one UserDefaults read per panel open.
struct StatsStrip: View {
    let today: Double

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
                Text("Today").font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Text(shortDuration(today)).font(.system(size: 10, weight: .medium))
            }
            if data.allSatisfy({ $0.seconds == 0 }) {
                // Seven stub bars read as a broken chart rather than as an empty one.
                Text("No focus time yet this week")
                    .font(.system(size: 10)).foregroundStyle(.tertiary)
                    .frame(height: 24, alignment: .bottom)
            } else {
                HStack(alignment: .bottom, spacing: 4) {
                    ForEach(data.indices, id: \.self) { i in
                        let entry = data[i]
                        let isToday = i == data.count - 1
                        VStack(spacing: 2) {
                            Capsule()
                                .fill(Color.accentColor.opacity(entry.seconds > 0 ? 0.7 : 0.18))
                                .frame(width: 10, height: max(3, 18 * entry.seconds / peak))
                            Text(Self.letter.string(from: entry.day))
                                .font(.system(size: 8, weight: isToday ? .bold : .regular))
                                .foregroundStyle(isToday ? Color.primary : Color.secondary)
                        }
                        .help("\(FocusStats.dayKey(entry.day)): \(shortDuration(entry.seconds))")
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: 30, alignment: .bottom)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Focused \(shortDuration(today)) today")
    }
}
