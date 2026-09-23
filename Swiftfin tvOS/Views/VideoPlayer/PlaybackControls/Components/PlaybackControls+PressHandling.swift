//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    func handlePressEvent(_ press: VideoPlayer.UIContainerViewController.PressEvent) {
        let isSeekPress = press.type == .leftArrow || press.type == .rightArrow

        if press.phase == .began,
           isSeekPress,
           !manager.item.isLiveStream,
           !viewState.isPresentingSupplement,
           viewState.presentation == .hidden || viewState.presentation == .progress || viewState.isProgressBarFocused
        {
            seekingPress = press.type
            viewState.showProgress()
        }

        // Retain ownership through ended/cancelled, even while the newly shown
        // slider is waiting for the focus engine to process our request.
        if seekingPress == press.type {
            viewState.refreshAutoDismiss()
            switch press.phase {
            case .began:
                if press.type == .rightArrow {
                    startSpeedBoost()
                }
            case .ended:
                if press.type == .rightArrow {
                    stopSpeedBoost(performJump: true)
                } else {
                    jumpBackward()
                }
                seekingPress = nil
            case .cancelled:
                stopSpeedBoost()
                seekingPress = nil
            default:
                break
            }
            press.resolve(.handled)
            return
        }

        if !viewState.isPresentingControls, press.phase == .began {
            viewState.showControls()
            press.resolve(.handled)
            return
        }

        viewState.refreshAutoDismiss()
        press.resolve(.fallback)
    }
}
