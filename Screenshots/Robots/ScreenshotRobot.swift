//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class ScreenshotRobot: Robot {

    private let configuration: ScreenshotConfiguration

    private var library: LibraryRobot!
    private var item: ItemRobot!

    private lazy var tabs = SelectUserRobot(app: app)
        .connect()
        .connect(to: configuration.server)
        .addUser()
        .signIn(username: configuration.username, password: configuration.password)

    init(app: XCUIApplication, configuration: ScreenshotConfiguration) {
        self.configuration = configuration
        super.init(app: app)
    }

    func capture(_ screenshot: Screenshot) {
        switch screenshot {
        case .home:
            tabs.home()
                .screenshot(.home)

        case .media:
            library = tabs.media()
                .screenshot(.media)

        case .library:
            library = library.library(configuration.movieLibrary)
                .screenshot(.library)

        case .movie:
            item = library.item(configuration.movie)
                .screenshot(.movie)

        case .series:
            item = item.goBack()
                .goBack()
                .library(configuration.showLibrary)
                .item(configuration.series)
                .screenshot(.series)

        case .episode:
            item = item.firstEpisode()
                .screenshot(.episode)

        case .playback:
            setPhoneLandscape(true)

            item.play()
                .aspectFill()
                .scrub(toProgress: 0.5) // don't screenshot title/vanity cards.
                .showControls()
                .screenshot(.playback, waitForIdle: false)

            setPhoneLandscape(false)

        case .userSelection:
            app.terminate()
            app.launch()

            tabs.settings()
                .switchUser()
                .screenshot(.userSelection)
        }
    }

    private func setPhoneLandscape(_ isLandscape: Bool) {
        #if os(iOS)
        if UIDevice.isPhone {
            XCUIDevice.shared.orientation = isLandscape ? .landscapeLeft : .portrait
        }
        #endif
    }
}
