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
    func testScreenshots() throws {
        let app = XCUIApplication()

        setupSnapshot(app)

        #if os(iOS)
        XCUIDevice.shared.orientation = UIDevice.isPad ? .landscapeLeft : .portrait
        #endif

        app.launch()

        let robot = Robot(app: app)

        robot.signIn(to: "https://demo.jellyfin.org/stable", username: "demo")
        robot.home().screenshot("Home")

        robot.media()
            .screenshot("Media")
            .library("Movies")
            .screenshot("Library")
            .item("Caminandes: Llama Drama")
            .screenshot("Movie")

        try robot.goBack().goBack().library("Shows").item("Pioneer One").screenshotDetail("Series", landscape: true)
        try robot.item("Season 1").item("Earthfall").screenshotDetail("Episode")

        guard !robot.isDuo else { return }

        setPhoneLandscape(true)

        robot.play()
            .preparePlayback(at: 0.5)
            .screenshot("Playback", waitForIdle: false)

        setPhoneLandscape(false)

        app.terminate()
        app.launch()
        robot.switchUser().screenshot("UserSelection")
    }

    @MainActor
    private func setPhoneLandscape(_ isLandscape: Bool) {
        #if os(iOS)
        if UIDevice.isPhone {
            XCUIDevice.shared.orientation = isLandscape ? .landscapeLeft : .portrait
        }
        #endif
    }
}
