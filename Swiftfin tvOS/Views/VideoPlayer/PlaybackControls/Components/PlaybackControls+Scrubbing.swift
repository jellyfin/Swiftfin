//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

extension VideoPlayer.PlaybackControls {

    func startSpeedBoost() {
        guard mediaSession.canControlPlayback, !isSpeedBoosting, speedBoostTimer == nil else { return }

        viewState.setInteraction(.speedBoost, active: true)

        speedBoostTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [self] _ in
            // This timer is scheduled on the main actor's run loop.
            MainActor.assumeIsolated {
                isSpeedBoosting = true
                viewState.originalPlaybackRate = mediaSession.rate

                let multiplier = Defaults[.VideoPlayer.Gesture.longPressSpeedMultiplier]
                mediaSession.rate = multiplier.rawValue

                toaster.present(
                    Text(multiplier.displayTitle),
                    systemName: "forward.fill"
                )
            }
        }
    }

    func stopSpeedBoost(performJump: Bool = false) {
        speedBoostTimer?.invalidate()
        speedBoostTimer = nil
        viewState.setInteraction(.speedBoost, active: false)

        if isSpeedBoosting {
            if let originalRate = viewState.originalPlaybackRate {
                mediaSession.rate = originalRate

                toaster.present(
                    Text(originalRate, format: .playbackRate),
                    systemName: "forward.fill"
                )
            }

            viewState.originalPlaybackRate = nil
            isSpeedBoosting = false
            return
        }

        if performJump {
            jumpForward()
        }
    }

    func jumpForward() {
        guard mediaSession.seek(by: jumpForwardInterval.rawValue) else { return }

        viewState.showProgress()
        viewState.jumpProgressObserver.jumpForward()

        toaster.present(
            Text(
                jumpForwardInterval.rawValue * viewState.jumpProgressObserver.jumps,
                format: .minuteSecondsAbbreviated
            ),
            systemName: "goforward"
        )
    }

    func jumpBackward() {
        guard mediaSession.seek(by: .zero - jumpBackwardInterval.rawValue) else { return }

        viewState.showProgress()
        viewState.jumpProgressObserver.jumpBackward()

        toaster.present(
            Text(
                jumpBackwardInterval.rawValue * viewState.jumpProgressObserver.jumps,
                format: .minuteSecondsAbbreviated
            ),
            systemName: "gobackward"
        )
    }
}
