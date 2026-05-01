//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    func handlePressEvent(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {

        if !containerState.isPresentingOverlay {
            containerState.isPresentingOverlay = true
            press.resolve(.handled)
            return
        }

        switch press.type {
        case .leftArrow:
            handleLeftArrow(press)
        case .rightArrow:
            handleRightArrow(press)
        default:
            containerState.timer.poke()
            press.resolve(.fallback)
        }
    }

    private func handleLeftArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent
    ) {
        guard containerState.isProgressBarFocused else {
            press.resolve(.fallback)
            return
        }

        switch press.phase {
        case .began:
            press.resolve(.handled)

        case .ended, .cancelled:
            jumpBackward()
            press.resolve(.handled)

        default:
            press.resolve(.fallback)
        }
    }

    private func handleRightArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent
    ) {
        guard containerState.isProgressBarFocused else {
            press.resolve(.fallback)
            return
        }

        switch press.phase {
        case .began:
            startSpeedBoost()
            press.resolve(.handled)

        case .ended, .cancelled:
            stopSpeedBoost(performJump: true)
            press.resolve(.handled)

        default:
            press.resolve(.fallback)
        }
    }
}
