import Foundation

/// Daily focus seconds, keyed yyyy-MM-dd in local time because the question is
/// "how long did I focus today", which is a wall-clock question.
public enum FocusStats {
    static let defaultsKey = "focus"

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    public static func dayKey(_ date: Date) -> String { formatter.string(from: date) }

    /// Credited to the day it is called on, not the day the session started — which is
    /// why a session running past midnight lands in both days with no special case.
    public static func add(_ seconds: Double,
                           to store: [String: Double],
                           now: Date) -> [String: Double] {
        guard seconds > 0 else { return store }
        var out = store
        let key = dayKey(now)
        out[key] = (out[key] ?? 0) + seconds
        return out
    }

    public static func load() -> [String: Double] {
        UserDefaults.standard.dictionary(forKey: defaultsKey) as? [String: Double] ?? [:]
    }

    public static func record(_ seconds: Double, now: Date = Date()) {
        UserDefaults.standard.set(add(seconds, to: load(), now: now), forKey: defaultsKey)
    }

    /// Monday through Sunday of the week `now` falls in, gaps filled with zero. Monday is
    /// forced rather than taken from the locale, so a day keeps its column on any region.
    public static func week(from store: [String: Double],
                            now: Date = Date()) -> [(day: Date, seconds: Double)] {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let monday = cal.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        return (0 ..< 7).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: monday) else { return nil }
            return (day, store[dayKey(day)] ?? 0)
        }
    }
}
