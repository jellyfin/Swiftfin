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

        let configuration = ScreenshotConfiguration(launchArguments: app.launchArguments)

        #if os(iOS)
        XCUIDevice.shared.orientation = UIDevice.current.userInterfaceIdiom == .pad ? .landscapeLeft : .portrait
        #endif

        app.launch()

        let tabs = SelectUserRobot(app: app)
            .connect()
            .connect(to: configuration.server)
            .addUser()
            .signIn(username: configuration.username, password: configuration.password)

        tabs.home()
            .screenshot(.home)

        let episodeItem = tabs.media()
            .screenshot(.media)
            .library(configuration.movieLibrary)
            .screenshot(.library)
            .item(configuration.movie)
            .screenshot(.movie)
            .goBack()
            .goBack()
            .library(configuration.showLibrary)
            .item(configuration.series)
            .screenshot(.series)
            .firstEpisode()
            .screenshot(.episode)

        setPhoneLandscape(true)

        episodeItem.play()
            .scrub(toProgress: 0.5) // don't screenshot title/vanity cards.
            .aspectFill()
            .showControls()
            .screenshot(.playback, waitForIdle: false)

        setPhoneLandscape(false)
        app.terminate()
        app.launch()

        tabs.settings()
            .switchUser()
            .screenshot(.userSelection)
    }

    @MainActor
    private func setPhoneLandscape(_ isLandscape: Bool) {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone {
            XCUIDevice.shared.orientation = isLandscape ? .landscapeLeft : .portrait
        }
        #endif
    }
}
