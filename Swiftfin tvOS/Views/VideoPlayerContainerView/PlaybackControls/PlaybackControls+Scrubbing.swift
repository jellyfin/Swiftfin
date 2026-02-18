//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

extension VideoPlayer.PlaybackControls {

    enum ScrubbingDirection {
        case forward
        case backward
    }

    // MARK: - Scrubbing

    func startScrubbing(direction: ScrubbingDirection) {
        if hasEnteredScrubMode, scrubbingDirection == direction {
            increaseScrubbingSpeed()
            return
        }

        if hasEnteredScrubMode, scrubbingDirection != direction {
            decreaseScrubbingSpeed(newDirection: direction)
            return
        }

        scrubbingDirection = direction
        scrubbingStartTime = Date()
        scrubbingSpeed = 0.0
        hasEnteredScrubMode = false
        containerState.scrubbedSeconds.value = manager.seconds

        scrubbingTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [self] _ in
            guard let startTime = scrubbingStartTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)

            if elapsed >= 0.5 && !hasEnteredScrubMode {
                scrubbingSpeed = 2.0
                hasEnteredScrubMode = true
                containerState.isScrubbing = true

                let speedText = "\(Int(scrubbingSpeed))×"
                toaster.present(
                    speedText,
                    systemName: scrubbingDirection == .forward ? "goforward" : "gobackward"
                )
            }

            guard hasEnteredScrubMode else { return }

            let scrubAmount = Duration.seconds(scrubbingSpeed * 0.2)
            if direction == .forward {
                containerState.scrubbedSeconds.value += scrubAmount
            } else {
                containerState.scrubbedSeconds.value -= scrubAmount
            }
        }
    }

    func increaseScrubbingSpeed() {
        if scrubbingSpeed == 2.0 {
            scrubbingSpeed = 4.0
        } else if scrubbingSpeed == 4.0 {
            scrubbingSpeed = 8.0
        } else if scrubbingSpeed == 8.0 {
            scrubbingSpeed = 16.0
        } else if scrubbingSpeed == 16.0 {
            scrubbingSpeed = 32.0
        }

        toaster.present(
            "\(Int(scrubbingSpeed))×",
            systemName: scrubbingDirection == .forward ? "goforward" : "gobackward"
        )
    }

    func decreaseScrubbingSpeed(newDirection: ScrubbingDirection) {
        if scrubbingSpeed == 2.0 {
            stopScrubbing()
            return
        } else if scrubbingSpeed == 4.0 {
            scrubbingSpeed = 2.0
        } else if scrubbingSpeed == 8.0 {
            scrubbingSpeed = 4.0
        } else if scrubbingSpeed == 16.0 {
            scrubbingSpeed = 8.0
        } else if scrubbingSpeed == 32.0 {
            scrubbingSpeed = 16.0
        }

        if scrubbingSpeed > 0 {
            toaster.present(
                "\(Int(scrubbingSpeed))×",
                systemName: scrubbingDirection == .forward ? "goforward" : "gobackward"
            )
        }
    }

    func stopScrubbing(performJump: Bool = false) {
        scrubbingTimer?.invalidate()
        scrubbingTimer = nil

        if performJump, let direction = scrubbingDirection, !hasEnteredScrubMode {
            if direction == .forward {
                containerState.jumpProgressObserver.jumpForward()
                toaster.present(
                    Text(
                        jumpForwardInterval.rawValue * containerState.jumpProgressObserver.jumps,
                        format: .minuteSecondsAbbreviated
                    ),
                    systemName: "goforward"
                )
                scheduleJump(direction: .forward)
            } else {
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
        } else if hasEnteredScrubMode {
            manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
        }

        containerState.isScrubbing = false
        scrubbingDirection = nil
        scrubbingSpeed = 0.0
        scrubbingStartTime = nil
        hasEnteredScrubMode = false
        scrubOriginSeconds = nil
    }

    func cancelScrubbing() {
        scrubbingTimer?.invalidate()
        scrubbingTimer = nil

        if let origin = scrubOriginSeconds {
            containerState.scrubbedSeconds.value = origin
        }

        containerState.isScrubbing = false
        scrubbingDirection = nil
        scrubbingSpeed = 0.0
        scrubbingStartTime = nil
        hasEnteredScrubMode = false
        scrubOriginSeconds = nil
    }

    func scheduleJump(direction: ScrubbingDirection) {
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
