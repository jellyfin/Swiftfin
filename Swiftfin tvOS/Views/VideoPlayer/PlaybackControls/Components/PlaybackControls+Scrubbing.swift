//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import SwiftUI

extension VideoPlayer.PlaybackControls {

    enum JumpDirection {
        case forward
        case backward
    }

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

    func scheduleJump(direction: JumpDirection) {
        pendingJumpWork?.cancel()

        let jumpCount = containerState.jumpProgressObserver.jumps
        let interval = direction == .forward
            ? jumpForwardInterval.rawValue
            : jumpBackwardInterval.rawValue

        let work = DispatchWorkItem { [weak manager, weak containerState] in
            guard let manager else { return }
            let totalDuration = interval * jumpCount

            // In a Watch Together group, coordinate the jump as a group seek (seek to the absolute target +
            // hold paused + resume everyone together on the server's command) instead of jumping the local
            // player ahead of the group and snapping back. Outside a group, jump locally as usual.
            let syncPlay = Container.shared.syncPlayManager()
            if syncPlay.state == .inGroup {
                let current = manager.seconds
                var target = direction == .forward ? current + totalDuration : max(.zero, current - totalDuration)
                if let runtime = manager.item.runtime {
                    target = min(target, runtime)
                }
                manager.proxy?.setSeconds(target)
                syncPlay.userDidSeek(toTicks: target.ticks)

                // While PAUSED, VLCKit's time-changed delegate doesn't fire (it only reflects active
                // playback), so `manager.seconds` would stay frozen at the pause point and every subsequent
                // jump would recompute the SAME `target` — landing in the same spot, never stacking. Write the
                // new position into the cache + scrubber so paused jumps accumulate (matching the relative
                // native jump the non-group path uses). Done AFTER `userDidSeek`, whose echo-suppression
                // window keeps this manual write from re-broadcasting as a fresh seek.
                manager.seconds = target
                containerState?.scrubbedSeconds.value = target
            } else {
                switch direction {
                case .forward:
                    manager.proxy?.jumpForward(totalDuration)
                case .backward:
                    manager.proxy?.jumpBackward(totalDuration)
                }
            }
            containerState?.jumpProgressObserver.reset()
        }

        pendingJumpWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: work)
    }
}
