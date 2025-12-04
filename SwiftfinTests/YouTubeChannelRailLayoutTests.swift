//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin
import XCTest

final class YouTubeChannelRailLayoutTests: XCTestCase {

    func testCollapsedIsRoughlyHalfExpandedWidth() {
        XCTAssertLessThanOrEqual(
            YouTubeChannelRailLayout.collapsedWidth * 2,
            YouTubeChannelRailLayout.expandedWidth + 1, // small tolerance
            "Collapsed rail should be about half the expanded width"
        )
    }

    func testWidthsArePositiveAndNonZero() {
        XCTAssertGreaterThan(YouTubeChannelRailLayout.collapsedWidth, 0)
        XCTAssertGreaterThan(YouTubeChannelRailLayout.expandedWidth, 0)
        XCTAssertGreaterThan(YouTubeChannelRailLayout.expandedWidth, YouTubeChannelRailLayout.collapsedWidth)
    }
}
