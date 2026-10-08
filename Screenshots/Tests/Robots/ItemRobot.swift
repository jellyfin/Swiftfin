//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import XCTest

final class ItemRobot: Robot {

    func play() -> VideoPlayerRobot {
        let playButtons = buttons(labeled: L10n.play)
        waitFor(playButtons.firstMatch)

        #if os(tvOS)
        let playButton = playButtons.allElementsBoundByIndex.first(where: \.hasFocus) ?? playButtons.firstMatch
        #else
        let playButton = playButtons.firstMatch
        #endif

        tap(playButton)
        sleep(8)

        return VideoPlayerRobot(app: app)
    }

    func firstEpisode() -> ItemRobot {
        #if os(iOS)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35)))
        #endif

        let episodeButtons = buttons(containing: L10n.episodeNumber(""))
        reveal(episodeButtons.firstMatch)
        waitFor(episodeButtons.firstMatch)

        let visibleButtons = episodeButtons.allElementsBoundByIndex
            .filter { app.frame.minX ... app.frame.maxX ~= $0.frame.midX }
        let firstColumn = visibleButtons.map(\.frame.minX).min() ?? 0

        let detailsButton = visibleButtons
            .filter { abs($0.frame.minX - firstColumn) < 50 }
            .max { $0.frame.minY < $1.frame.minY } ?? episodeButtons.firstMatch

        tap(detailsButton)
        return ItemRobot(app: app)
    }

    func goBack() -> LibraryRobot {
        back()
        return LibraryRobot(app: app)
    }
}
