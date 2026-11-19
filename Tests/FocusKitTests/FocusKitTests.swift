import XCTest
@testable import FocusKit

final class GeometryTests: XCTestCase {
    /// CG is top-left origin, AppKit bottom-left. Getting this backwards is the classic
    /// way these overlays break, and it only shows up on a second display.
    func testFlipOnPrimaryScreen() {
        let flipped = cocoaRect(CGRect(x: 100, y: 50, width: 400, height: 300), screenTop: 1080)
        XCTAssertEqual(flipped, CGRect(x: 100, y: 730, width: 400, height: 300))
    }

    func testFlipAboveAndLeftOfOrigin() {
        // A display placed above-left of the primary one has negative CG coordinates.
        let flipped = cocoaRect(CGRect(x: -1920, y: -200, width: 800, height: 600), screenTop: 1080)
        XCTAssertEqual(flipped, CGRect(x: -1920, y: 680, width: 800, height: 600))
    }

    func testFlipIsItsOwnInverse() {
        let original = CGRect(x: 10, y: 20, width: 30, height: 40)
        XCTAssertEqual(cocoaRect(cocoaRect(original, screenTop: 900), screenTop: 900), original)
    }
}

final class DurationTests: XCTestCase {
    func testBelowAMinuteReadsZero() {
        XCTAssertEqual(shortDuration(0), "0m")
        XCTAssertEqual(shortDuration(59), "0m")
    }

    func testMinutesAndHours() {
        XCTAssertEqual(shortDuration(60), "1m")
        XCTAssertEqual(shortDuration(42 * 60), "42m")
        XCTAssertEqual(shortDuration(3600 + 42 * 60), "1h 42m")
    }

    /// Never rolls over into days: a 26-hour total should still read in hours.
    func testPastADay() {
        XCTAssertEqual(shortDuration(26 * 3600 + 5 * 60), "26h 5m")
    }

    func testNegativeClampsToZero() {
        XCTAssertEqual(shortDuration(-10), "0m")
    }
}

final class FocusStatsTests: XCTestCase {
    private let noon = Date(timeIntervalSince1970: 1_700_000_000)

    func testCreditsToday() {
        let out = FocusStats.add(90, to: [:], now: noon)
        XCTAssertEqual(out[FocusStats.dayKey(noon)], 90)
    }

    func testAccumulates() {
        var store = FocusStats.add(90, to: [:], now: noon)
        store = FocusStats.add(30, to: store, now: noon)
        XCTAssertEqual(store[FocusStats.dayKey(noon)], 120)
    }

    /// A session running past midnight is credited to the day each flush lands on, so
    /// it splits across both days with no explicit midnight handling.
    func testCrossesMidnight() {
        let yesterday = noon.addingTimeInterval(-86_400)
        var store = FocusStats.add(600, to: [:], now: yesterday)
        store = FocusStats.add(300, to: store, now: noon)
        XCTAssertEqual(store[FocusStats.dayKey(yesterday)], 600)
        XCTAssertEqual(store[FocusStats.dayKey(noon)], 300)
        XCTAssertEqual(store.count, 2)
    }

    func testZeroIsNotRecorded() {
        XCTAssertTrue(FocusStats.add(0, to: [:], now: noon).isEmpty)
    }

    /// Gaps must come back as zeros, or the bar strip would shift its columns around.
    func testLastDaysFillsGaps() {
        let store = [FocusStats.dayKey(noon): 120.0]
        let week = FocusStats.lastDays(7, from: store, now: noon)
        XCTAssertEqual(week.count, 7)
        XCTAssertEqual(week.last?.seconds, 120)
        XCTAssertEqual(week.dropLast().map(\.seconds), Array(repeating: 0, count: 6))
    }
}

final class NudgeTests: XCTestCase {
    func testSilentInsideGrace() {
        XCTAssertFalse(shouldNudge(awayFor: 4, sinceLastNudge: .infinity, grace: 5))
    }

    func testFiresOnceGraceIsPast() {
        XCTAssertTrue(shouldNudge(awayFor: 5, sinceLastNudge: .infinity, grace: 5))
    }

    func testQuietRightAfterFiring() {
        XCTAssertFalse(shouldNudge(awayFor: 6, sinceLastNudge: 0, grace: 5))
    }

    func testRepeatsAfterTheInterval() {
        XCTAssertFalse(shouldNudge(awayFor: 19, sinceLastNudge: 14, grace: 5))
        XCTAssertTrue(shouldNudge(awayFor: 20, sinceLastNudge: nudgeRepeat, grace: 5))
    }

    /// A grace longer than the repeat interval must still hold its full grace.
    func testLongGraceStillHolds() {
        XCTAssertFalse(shouldNudge(awayFor: 20, sinceLastNudge: .infinity, grace: 30))
        XCTAssertTrue(shouldNudge(awayFor: 30, sinceLastNudge: .infinity, grace: 30))
    }
}
