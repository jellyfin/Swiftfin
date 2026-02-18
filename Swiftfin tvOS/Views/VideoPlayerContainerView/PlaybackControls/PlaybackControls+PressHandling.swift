//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    // MARK: - Press Event Router

    func handlePressEvent(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {

        if !isPresentingOverlay {
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

    // MARK: - Left Arrow

    private func handleLeftArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent
    ) {
        guard isProgressBarFocused else {
            press.resolve(.fallback)
            return
        }

        switch press.phase {
        case .began:
            startScrubbing(direction: .backward)
            press.resolve(.handled)

        case .ended, .cancelled:
            stopScrubbing(performJump: true)
            press.resolve(.handled)

        default:
            press.resolve(.fallback)
        }
    }

    // MARK: - Right Arrow

    private func handleRightArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent
    ) {
        guard isProgressBarFocused else {
            press.resolve(.fallback)
            return
        }

        switch press.phase {
        case .began:
            startScrubbing(direction: .forward)
            press.resolve(.handled)

        case .ended, .cancelled:
            stopScrubbing(performJump: true)
            press.resolve(.handled)

        default:
            press.resolve(.fallback)
        }
    }
}
