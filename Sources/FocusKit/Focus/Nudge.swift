import Foundation

public let nudgeRepeat: TimeInterval = 15

/// Pure so the escalation can be tested without a window server: silent until `grace`
/// has passed, then one shake every `repeatEvery` for as long as you stay away.
/// Pass `.infinity` for `sinceLastNudge` when nothing has fired yet.
public func shouldNudge(awayFor: TimeInterval,
                        sinceLastNudge: TimeInterval,
                        grace: TimeInterval,
                        repeatEvery: TimeInterval = nudgeRepeat) -> Bool {
    awayFor >= grace && sinceLastNudge >= repeatEvery
}
