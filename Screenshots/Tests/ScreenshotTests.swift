//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)

        #if os(iOS)
        XCUIDevice.shared.orientation = UIDevice.isPad ? .landscapeLeft : .portrait
        #endif

        app.launch()

        let robot = ScreenshotRobot(app: app, configuration: ScreenshotConfiguration(launchArguments: app.launchArguments))

        for screenshot in Screenshot.allCases {
            robot.capture(screenshot)
        }
    }
}
