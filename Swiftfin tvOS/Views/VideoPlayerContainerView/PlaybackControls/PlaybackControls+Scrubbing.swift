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

    enum JumpDirection {
        case forward
        case backward
    }

    // MARK: - Speed Boost

    func startSpeedBoost() {
        guard !isSpeedBoosting else { return }

        speedBoostTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [self] _ in
            isSpeedBoosting = true
            containerState.originalPlaybackRate = manager.rate

            let multiplier = Defaults[.VideoPlayer.Gesture.longPressSpeedMultiplier]
            manager.setRate(rate: multiplier.rawValue)

            toaster.present(
                Text(multiplier.displayTitle),
                systemName: "forward.fill"
            )
        }
    }

    func stopSpeedBoost(performJump: Bool = false) {
        speedBoostTimer?.invalidate()
        speedBoostTimer = nil

        if isSpeedBoosting {
            if let originalRate = containerState.originalPlaybackRate {
                manager.setRate(rate: originalRate)

                toaster.present(
                    Text(originalRate, format: .playbackRate),
                    systemName: "forward.fill"
                )
            }

            containerState.originalPlaybackRate = nil
            isSpeedBoosting = false
            return
        }

        if performJump {
            jumpForward()
        }
    }

    // MARK: - Jumping

    func jumpForward() {
        containerState.jumpProgressObserver.jumpForward()
        toaster.present(
            Text(
                jumpForwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                format: .minuteSecondsAbbreviated
            ),
            systemName: "goforward"
        )
        scheduleJump(direction: .forward)
    }

    func jumpBackward() {
        containerState.jumpProgressObserver.jumpBackward()
        toaster.present(
            Text(
                jumpBackwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                format: .minuteSecondsAbbreviated
            ),
            systemName: "gobackward"
        )
        scheduleJump(direction: .backward)
    }

    // MARK: - Scrubbing

    func cancelScrubbing() {
        if let origin = scrubOriginSeconds {
            containerState.scrubbedSeconds.value = origin
        }

        containerState.isScrubbing = false
        hasEnteredScrubMode = false
        scrubOriginSeconds = nil
    }

    func scheduleJump(direction: JumpDirection) {
        pendingJumpWork?.cancel()

        let jumpCount = containerState.jumpProgressObserver.jumps
        let interval = direction == .forward
            ? jumpForwardInterval.rawValue
            : jumpBackwardInterval.rawValue

        let work = DispatchWorkItem { [weak manager, weak containerState] in
            let totalDuration = interval * jumpCount
            if direction == .forward {
                manager?.proxy?.jumpForward(totalDuration)
            } else {
                manager?.proxy?.jumpBackward(totalDuration)
            }
            containerState?.jumpProgressObserver.reset()
        }

        pendingJumpWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
}
