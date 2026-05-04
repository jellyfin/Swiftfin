//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_iOS
import XCTest

/// Covers `RuntimeFormatStyle` which switches between minute:second and
/// hour:minute:second patterns based on a 3600-second threshold. The
/// format-style selection is the high-risk piece — a regression here
/// would silently mis-format runtime everywhere it's displayed.
final class RuntimeFormatStyleTests: XCTestCase {

    private let style = RuntimeFormatStyle()

    func testZeroDuration() {
        XCTAssertEqual(style.format(.seconds(0)), "0:00")
    }

    func testJustUnderOneHourUsesMinuteSecondPattern() {
        XCTAssertEqual(style.format(.seconds(3599)), "59:59")
    }

    func testExactlyOneHourSwitchesToHourMinuteSecond() {
        // The threshold is `>= 3600` seconds; this exact value must
        // produce the three-component output.
        let formatted = style.format(.seconds(3600))
        XCTAssertTrue(
            formatted.contains(":00:00"),
            "Expected hour:minute:second output at the 1h boundary, got '\(formatted)'"
        )
    }

    func testOverOneHourUsesHourMinuteSecond() {
        let formatted = style.format(.seconds(7261))
        XCTAssertTrue(
            formatted.contains(":01:01"),
            "Expected runtime to format with seconds zero-padded, got '\(formatted)'"
        )
    }

    func testWholeSecondInputProducesPaddedOutput() {
        // Single-digit minute and second values are zero-padded to two
        // characters in the minute:second branch.
        XCTAssertEqual(style.format(.seconds(65)), "1:05")
    }
}
