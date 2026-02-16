//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    // MARK: - Focus Zone

    enum FocusZone {
        case navBar
        case progressBar
        case tabButtons
        case supplementContent
    }

    var currentFocusZone: FocusZone {
        if isPlaybackProgressFocused {
            return .progressBar
        } else if focusedSupplementID != nil {
            return .tabButtons
        } else if isPresentingSupplement {
            return .supplementContent
        } else {
            return .navBar
        }
    }

    // MARK: - Press Event Router

    func handlePressEvent(_ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent) {

        if !isPresentingOverlay {
            handlePressWhileOverlayHidden(press)
            return
        }

        if press.phase == .began {
            pressBeganZone = currentFocusZone
        }

        let zone = pressBeganZone ?? currentFocusZone

        switch press.type {
        case .upArrow:
            handleUpArrow(press, zone: zone)
        case .downArrow:
            handleDownArrow(press, zone: zone)
        case .leftArrow:
            handleLeftArrow(press, zone: zone)
        case .rightArrow:
            handleRightArrow(press, zone: zone)
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

    // MARK: - Up Arrow

    private func handleUpArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent,
        zone: FocusZone
    ) {
        switch press.phase {
        case .began:
            switch zone {
            case .tabButtons, .supplementContent:
                press.resolve(.handled)
            default:
                press.resolve(.fallback)
            }

        case .ended:
            switch zone {
            case .tabButtons:
                containerState.selectedSupplement = nil
                containerState.containerView?.presentSupplementContainer(false, redirectFocus: false)
                containerState.timer.poke()
                isPlaybackProgressFocused = true
                press.resolve(.handled)
            case .supplementContent:
                let targetID = containerState.selectedSupplement?.id ?? currentSupplements.first?.id
                isRedirectingToTab = true
                containerState.containerView?.redirectFocusToPlaybackControls()
                containerState.timer.poke()
                DispatchQueue.main.async {
                    focusedSupplementID = targetID
                    isRedirectingToTab = false
                }
                press.resolve(.handled)
            default:
                press.resolve(.fallback)
            }

        default:
            press.resolve(.fallback)
        }
    }

    // MARK: - Down Arrow

    private func handleDownArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent,
        zone: FocusZone
    ) {
        switch press.phase {
        case .began:
            switch zone {
            case .progressBar where !currentSupplements.isEmpty,
                 .tabButtons where isPresentingSupplement:
                press.resolve(.handled)
            default:
                press.resolve(.fallback)
            }

        case .ended:
            switch zone {
            case .progressBar where !currentSupplements.isEmpty:
                let targetID = containerState.selectedSupplement?.id ?? currentSupplements.first?.id
                focusedSupplementID = targetID
                containerState.timer.poke()
                press.resolve(.handled)
            case .tabButtons where isPresentingSupplement:
                containerState.supplementContentNeedsFocus = true
                containerState.containerView?.redirectFocusToSupplementContent()
                containerState.timer.poke()
                press.resolve(.handled)
            default:
                press.resolve(.fallback)
            }

        default:
            press.resolve(.fallback)
        }
    }

    // MARK: - Left Arrow

    private func handleLeftArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent,
        zone: FocusZone
    ) {
        switch press.phase {
        case .began:
            if zone == .progressBar {
                startScrubbing(direction: .backward)
                press.resolve(.handled)
            } else if zone == .tabButtons {
                if let currentID = focusedSupplementID,
                   let currentIndex = currentSupplements.index(id: currentID),
                   currentIndex > currentSupplements.startIndex
                {
                    let previousIndex = currentSupplements.index(before: currentIndex)
                    focusedSupplementID = currentSupplements[previousIndex].id
                }
                press.resolve(.handled)
            } else {
                press.resolve(.fallback)
            }

        case .ended, .cancelled:
            if scrubbingDirection == .backward, !hasEnteredScrubMode {
                stopScrubbing(performJump: true)
                press.resolve(.handled)
            } else if scrubbingDirection == .backward {
                press.resolve(.handled)
            } else if zone == .tabButtons {
                press.resolve(.handled)
            } else {
                press.resolve(.fallback)
            }

        default:
            press.resolve(.fallback)
        }
    }

    // MARK: - Right Arrow

    private func handleRightArrow(
        _ press: VideoPlayer.UIVideoPlayerContainerViewController.PressEvent,
        zone: FocusZone
    ) {
        switch press.phase {
        case .began:
            if zone == .progressBar {
                startScrubbing(direction: .forward)
                press.resolve(.handled)
            } else if zone == .tabButtons {
                if let currentID = focusedSupplementID,
                   let currentIndex = currentSupplements.index(id: currentID)
                {
                    let nextIndex = currentSupplements.index(after: currentIndex)
                    if nextIndex < currentSupplements.endIndex {
                        focusedSupplementID = currentSupplements[nextIndex].id
                    }
                }
                press.resolve(.handled)
            } else {
                press.resolve(.fallback)
            }

        case .ended, .cancelled:
            if scrubbingDirection == .forward, !hasEnteredScrubMode {
                stopScrubbing(performJump: true)
                press.resolve(.handled)
            } else if scrubbingDirection == .forward {
                press.resolve(.handled)
            } else if zone == .tabButtons {
                press.resolve(.handled)
            } else {
                press.resolve(.fallback)
            }

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
            isPlaybackProgressFocused = true
            press.resolve(.handled)
        } else {
            isPresentingCloseConfirmation = true
            press.resolve(.handled)
        }
    }
}
