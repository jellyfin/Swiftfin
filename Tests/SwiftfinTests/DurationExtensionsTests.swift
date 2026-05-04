//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_iOS
import XCTest

/// Covers the `Duration` extensions. Jellyfin's API encodes durations
/// as 100-nanosecond ticks (10 ticks per microsecond, 10_000_000 per
/// second). The conversion is used everywhere runtime is decoded from
/// the server, so a regression here would shift every displayed time.
final class DurationExtensionsTests: XCTestCase {

    func testTicksConvertsTenMillionToOneSecond() {
        XCTAssertEqual(Duration.ticks(10_000_000), .seconds(1))
    }

    func testTicksRoundsBelowOneMicrosecondToZero() {
        // Integer division by 10 truncates: anything under 10 ticks
        // collapses to zero microseconds.
        XCTAssertEqual(Duration.ticks(0), .seconds(0))
        XCTAssertEqual(Duration.ticks(9), .microseconds(0))
        XCTAssertEqual(Duration.ticks(10), .microseconds(1))
    }

    func testMinutesIntegerOverloadProducesExactSeconds() {
        XCTAssertEqual(Duration.minutes(1 as Int), .seconds(60))
        XCTAssertEqual(Duration.minutes(90 as Int), .seconds(5400))
    }

    func testHoursIntegerOverloadProducesExactSeconds() {
        XCTAssertEqual(Duration.hours(1 as Int), .seconds(3600))
        XCTAssertEqual(Duration.hours(24 as Int), .seconds(86400))
    }

    func testSecondsAccessorRoundTripsForWholeValues() {
        // Whole-second durations must round-trip without floating-point drift.
        XCTAssertEqual(Duration.seconds(0).seconds, 0, accuracy: 1e-9)
        XCTAssertEqual(Duration.seconds(3600).seconds, 3600, accuracy: 1e-9)
        XCTAssertEqual(Duration.minutes(45 as Int).seconds, 2700, accuracy: 1e-9)
    }

    func testMinutesAccessorDividesSeconds() {
        XCTAssertEqual(Duration.seconds(120).minutes, 2, accuracy: 1e-9)
        XCTAssertEqual(Duration.seconds(90).minutes, 1.5, accuracy: 1e-9)
    }
}
