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

        // GuamaFlix Skip Intro/Credits: in full screen the player routes Select/Back through this
        // `onPressEvent` path (notably on the simulator) rather than as `.select`/`.menu`. While the
        // full-screen pill is showing, Select skips the segment and Back dismisses it — both consume the
        // press so the transport bar doesn't appear. (On a physical Apple TV, Select/Back arrive as
        // `.select`/`.menu` and are handled by `handleSelectEnded`/`handleMenuEnded`; the raw values here
        // cover the simulator's Select=2040 / Back=2041.)
        if !containerState.isPresentingOverlay, SkipSegmentState.shared.isShowing {
            let raw = press.type.rawValue
            let isBack = press.type == .menu || raw == 2041
            let isSelect = press.type == .select || raw == 2040

            if isBack {
                if press.phase == .began {
                    SkipSegmentState.shared.dismiss()
                }
                press.resolve(.handled)
                return
            }

            if isSelect {
                if press.phase == .began {
                    SkipSegmentState.shared.skip()
                }
                press.resolve(.handled)
                return
            }
            // Any other press in this state falls through to reveal the controls.
        }

        if !containerState.isPresentingOverlay {
            // Right after a full-screen dismiss, swallow the trailing presses of that Back action so the
            // transport bar doesn't appear.
            if SkipSegmentState.shared.shouldSwallowWakePress {
                press.resolve(.handled)
                return
            }

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
