//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_iOS
import XCTest

/// Covers `FixedWidthInteger.timeLabel` — the playback-position formatter
/// shown in the player overlay. The output format conditionally includes
/// hours, so the boundary at exactly 1h is the high-risk case.
final class IntTimeLabelTests: XCTestCase {

    func testZeroSeconds() {
        XCTAssertEqual(0.timeLabel, "0:00")
    }

    func testUnderOneMinute() {
        XCTAssertEqual(7.timeLabel, "0:07")
        XCTAssertEqual(59.timeLabel, "0:59")
    }

    func testUnderOneHourDoesNotShowHours() {
        XCTAssertEqual(60.timeLabel, "1:00")
        XCTAssertEqual(599.timeLabel, "9:59")
        XCTAssertEqual(3599.timeLabel, "59:59")
    }

    func testOneHourBoundaryShowsHours() {
        // Exactly 1h must include the hours field and zero-pad minutes.
        XCTAssertEqual(3600.timeLabel, "1:00:00")
    }

    func testOverOneHourPadsMinutesAndSeconds() {
        XCTAssertEqual(3661.timeLabel, "1:01:01")
        XCTAssertEqual(7261.timeLabel, "2:01:01")
    }

    func testHoursDoNotRollOverAtTwentyFour() {
        // Some content (live streams, audiobooks) can exceed 24 hours.
        XCTAssertEqual(86399.timeLabel, "23:59:59")
        XCTAssertEqual(360_000.timeLabel, "100:00:00")
    }
}
