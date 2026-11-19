import XCTest
@testable import FocusKit

final class AttentionLogTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 0)
    private func at(_ s: Double) -> Date { t0.addingTimeInterval(s) }

    /// The whole point: thirty short hops and one long defection give the same away
    /// time, and only the switch count tells them apart.
    func testShortHopsCountEvenWhenTheyNeverNudge() {
        var log = AttentionLog(start: t0)
        for i in 0 ..< 10 {
            let base = Double(i) * 60
            log.sample(.away("Slack"), at: at(base + 50))
            log.sample(.target, at: at(base + 53))
        }
        log.finish(at: at(600))

        XCTAssertEqual(log.switches, 10)
        XCTAssertEqual(log.away, 30, accuracy: 0.001)
        XCTAssertEqual(log.apps["Slack"], AttentionLog.Drift(count: 10, seconds: 30))

        var defector = AttentionLog(start: t0)
        defector.sample(.away("Slack"), at: at(100))
        defector.sample(.target, at: at(130))
        defector.finish(at: at(600))
        XCTAssertEqual(defector.away, log.away, accuracy: 0.001)
        XCTAssertEqual(defector.switches, 1)
        XCTAssertGreaterThan(defector.longest, log.longest)
    }

    func testLongestIsTheUnbrokenStretchNotTheTotal() {
        var log = AttentionLog(start: t0)
        log.sample(.away("Mail"), at: at(120))
        log.sample(.target, at: at(130))
        log.finish(at: at(400))

        XCTAssertEqual(log.onTarget, 390, accuracy: 0.001)
        XCTAssertEqual(log.longest, 270, accuracy: 0.001)
        XCTAssertEqual(log.firstDrift, 120)
    }

    func testFirstDriftKeepsTheFirstOne() {
        var log = AttentionLog(start: t0)
        log.sample(.away("Mail"), at: at(90))
        log.sample(.target, at: at(95))
        log.sample(.away("Safari"), at: at(300))
        log.finish(at: at(310))

        XCTAssertEqual(log.firstDrift, 90)
        XCTAssertEqual(log.apps.count, 2)
    }

    /// A granted peek must not read as drift — it is already counted as a peek.
    func testUnknownFreezesRatherThanSplitting() {
        var log = AttentionLog(start: t0)
        log.sample(.unknown, at: at(60))
        log.finish(at: at(120))

        XCTAssertEqual(log.switches, 0)
        XCTAssertEqual(log.away, 0)
        XCTAssertEqual(log.longest, 120, accuracy: 0.001)
        XCTAssertNil(log.firstDrift)
    }

    func testSamplingEveryTickDoesNotInflateCounts() {
        var log = AttentionLog(start: t0)
        for i in 0 ..< 300 { log.sample(.target, at: at(Double(i) / 30)) }
        for i in 300 ..< 600 { log.sample(.away("Safari"), at: at(Double(i) / 30)) }
        log.finish(at: at(20))

        XCTAssertEqual(log.switches, 1)
        XCTAssertEqual(log.onTarget, 10, accuracy: 0.001)
        XCTAssertEqual(log.away, 10, accuracy: 0.001)
    }

    func testFinishIsIdempotent() {
        var log = AttentionLog(start: t0)
        log.finish(at: at(100))
        log.finish(at: at(100))
        XCTAssertEqual(log.onTarget, 100, accuracy: 0.001)
    }

    func testLineCarriesTheFieldsWorthReadingBack() {
        var log = AttentionLog(start: t0)
        log.sample(.away("Slack"), at: at(120))
        log.finish(at: at(180))
        let line = SessionLog.line(log, start: t0, end: at(180), planned: 25, targets: 1,
                                   mode: "dim", preset: nil, nudges: 2, peeks: 1,
                                   ended: "user")

        XCTAssertEqual(line["switches"] as? Int, 1)
        XCTAssertEqual(line["planned"] as? Int, 1500)
        XCTAssertEqual(line["first_drift"] as? Double, 120)
        XCTAssertEqual(line["ended"] as? String, "user")
        XCTAssertNil(line["preset"])
        XCTAssertTrue(JSONSerialization.isValidJSONObject(line))
    }
}
