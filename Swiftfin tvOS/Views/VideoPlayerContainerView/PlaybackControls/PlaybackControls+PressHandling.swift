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
            handlePressWhileOverlayHidden(press)
            return
        }

        switch press.type {
        case .leftArrow:
            handleLeftArrow(press)
        case .rightArrow:
            handleRightArrow(press)
        case .playPause:
            handlePlayPause(press)
        case .select:
            handleSelect(press)
        case .menu:
            handleMenu(press)
        default:
            containerState.timer.poke()
            press.resolve(.fallback)
        }
    }

    // MARK: - Overlay Hidden

    private func handlePressWhileOverlayHidden(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent
    ) {
        if press.type == .playPause {
            if manager.playbackRequestStatus == .paused {
                manager.setPlaybackRequestStatus(status: .playing)
                toaster.present(L10n.play, systemName: "play.circle")
            }
            containerState.isPresentingOverlay = true
            press.resolve(.handled)
        } else {
            containerState.isPresentingOverlay = true
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
            if scrubbingDirection == .backward, !hasEnteredScrubMode {
                stopScrubbing(performJump: true)
            }
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
            if scrubbingDirection == .forward, !hasEnteredScrubMode {
                stopScrubbing(performJump: true)
            }
            press.resolve(.handled)

        default:
            press.resolve(.fallback)
        }
    }

    // MARK: - Play/Pause

    private func handlePlayPause(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {
        if hasEnteredScrubMode {
            manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
            stopScrubbing(performJump: false)
        }

        switch manager.playbackRequestStatus {
        case .playing:
            manager.setPlaybackRequestStatus(status: .paused)
        case .paused:
            manager.setPlaybackRequestStatus(status: .playing)
        }
        containerState.timer.poke()
        press.resolve(.handled)
    }

    // MARK: - Select

    private func handleSelect(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {
        if hasEnteredScrubMode {
            manager.proxy?.setSeconds(containerState.scrubbedSeconds.value)
            stopScrubbing(performJump: false)
            manager.setPlaybackRequestStatus(status: .playing)
            containerState.timer.poke()
            press.resolve(.handled)
        } else {
            press.resolve(.fallback)
        }
    }

    // MARK: - Menu

    private func handleMenu(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {
        if isPresentingSupplement {
            containerState.selectedSupplement = nil
            containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)
            containerState.timer.poke()
            focusGuide.transition(to: "progressBar")
            press.resolve(.handled)
        } else {
            isPresentingCloseConfirmation = true
            press.resolve(.handled)
        }
    }
}
