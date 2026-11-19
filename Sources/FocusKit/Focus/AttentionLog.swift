import Foundation

/// One session's attention record, built from samples of where the frontmost window was.
/// Pure so the segment accounting can be tested without a window server.
///
/// Counting is deliberately independent of `nudgeGrace`: a three-second glance at Slack
/// never shoves, and is exactly the switch worth counting — away time alone cannot tell
/// thirty short hops from one long defection.
public struct AttentionLog {
    public struct Drift: Equatable {
        public var count = 0
        public var seconds: Double = 0
    }

    public enum Place: Equatable {
        case target
        /// Carries the app name, which is what "what did I switch to" is asking for.
        case away(String)
        /// Freezes the open segment rather than ending it: our own panel, a granted peek,
        /// or a window CG has lost. ponytail: the frozen span is credited to whatever
        /// segment was running, which flatters a long peek. Split it out if peeks grow.
        case unknown
    }

    public private(set) var switches = 0
    public private(set) var away: Double = 0
    public private(set) var onTarget: Double = 0
    /// Longest unbroken stretch on a target — the one number that says whether the
    /// session contained a block long enough to do hard work in.
    public private(set) var longest: Double = 0
    public private(set) var firstDrift: Double?
    public private(set) var apps: [String: Drift] = [:]

    private let start: Date
    private var since: Date
    private var place: Place = .target

    public init(start: Date) {
        self.start = start
        since = start
    }

    public mutating func sample(_ now: Place, at date: Date) {
        if case .unknown = now { return }
        guard now != place else { return }
        close(at: date)
        if case .away(let app) = now {
            switches += 1
            apps[app, default: Drift()].count += 1
            if firstDrift == nil { firstDrift = date.timeIntervalSince(start) }
        }
        place = now
    }

    /// Closes the trailing segment. Idempotent, so a double stop costs nothing.
    public mutating func finish(at date: Date) { close(at: date) }

    private mutating func close(at date: Date) {
        let span = max(0, date.timeIntervalSince(since))
        since = date
        switch place {
        case .target:
            onTarget += span
            longest = max(longest, span)
        case .away(let app):
            away += span
            apps[app, default: Drift()].seconds += span
        case .unknown:
            break
        }
    }
}
