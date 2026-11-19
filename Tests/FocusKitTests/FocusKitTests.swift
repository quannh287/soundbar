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

final class ScreenPickTests: XCTestCase {
    /// Roughly this machine: a laptop at the origin with two displays above it.
    private let frames = [
        CGRect(x: 0, y: 0, width: 1680, height: 1050),
        CGRect(x: 733, y: 1050, width: 1920, height: 1080),
        CGRect(x: -1187, y: 1050, width: 1920, height: 1080),
    ]

    func testWindowWhollyOnOneScreen() {
        let w = CGRect(x: 800, y: 1200, width: 600, height: 400)
        XCTAssertEqual(indexOfMostOverlap(w, in: frames), 1)
    }

    func testNegativeOriginScreen() {
        let w = CGRect(x: -1000, y: 1100, width: 300, height: 300)
        XCTAssertEqual(indexOfMostOverlap(w, in: frames), 2)
    }

    /// A window straddling two displays must resolve to one, not to whichever is listed
    /// first — that is the case the jolt would otherwise fire on the wrong screen for.
    func testStraddlingPicksTheLargerShare() {
        // 400x250 on the laptop against 267x150 on the display above it.
        let straddling = CGRect(x: 600, y: 800, width: 400, height: 400)
        XCTAssertEqual(indexOfMostOverlap(straddling, in: frames), 0)
        let other = CGRect(x: 700, y: 1000, width: 400, height: 400)
        XCTAssertEqual(indexOfMostOverlap(other, in: frames), 1)
    }

    func testOffAllScreens() {
        XCTAssertNil(indexOfMostOverlap(CGRect(x: 9000, y: 9000, width: 10, height: 10),
                                        in: frames))
    }

    func testEmptyRectTouchesNothing() {
        XCTAssertNil(indexOfMostOverlap(CGRect(x: 100, y: 100, width: 0, height: 0),
                                        in: frames))
    }
}
