//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_tvOS
import XCTest

final class DurationTicksTests: XCTestCase {

    func testTenMillionTicksIsOneSecond() {
        XCTAssertEqual(Duration.ticks(10_000_000), .seconds(1))
    }
}
