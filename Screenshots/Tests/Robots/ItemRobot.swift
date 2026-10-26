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

        let player = VideoPlayerRobot(app: app)

        #if os(tvOS)
        for _ in 0 ..< 5 where focusedLabel != L10n.play {
            XCUIRemote.shared.press(.up)
            sleep(1)
        }

        // Playback can stall on its first load, so back out and start it again.
        for _ in 0 ..< 3 {
            XCUIRemote.shared.press(.select)

            if player.waitForPlayback() {
                break
            }

            XCUIRemote.shared.press(.menu)
            sleep(3)

            if focusedLabel != L10n.play {
                XCUIRemote.shared.press(.menu)
                sleep(3)
            }
        }
        #else
        tap(playButtons.firstMatch)
        sleep(8)
        #endif

        return player
    }
}
