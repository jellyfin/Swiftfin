//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: multitap refinements
//       - don't increment jump progress if hit ends
//       - verify if ending media

extension VideoPlayer.UIContainerViewController {

    func checkGestureLock() -> Bool {
        if viewState.isGestureLocked {
            viewState.toastProxy.present(
                L10n.pressAndHoldToUnlock,
                systemName: VideoPlayerActionButton.gestureLock.systemImage
            )

            return false
        }

        return true
    }

    func handleTapGesture(
        location: CGPoint,
        unitPoint: UnitPoint,
        count: Int
    ) {
        if count == 1 {
            guard checkGestureLock() else { return }

            handleSingleTapGesture(
                location: location,
                unitPoint: unitPoint
            )
        }

        if count == 2 {
            handleDoubleTouchGesture(
                location: location,
                unitPoint: unitPoint
            )
        }
    }

    private func handleSingleTapGesture(
        location: CGPoint,
        unitPoint: UnitPoint
    ) {
        let action = Defaults[.VideoPlayer.Gesture.multiTapGesture]
        let canMultiTap = action != .none && viewState.mediaSession?.canSeek == true

        guard canMultiTap else {
            viewState.cancelTapGesture()
            performSingleTapGesture()
            return
        }

        let jumpProgressObserver = viewState.jumpProgressObserver
        let width = unitPoint.x > 0 ? location.x / unitPoint.x : view.bounds.width
        var isMultiTap = false

        switch action {
        case .none:
            ()
        case .jump:
            if canMultiTap, let lastTapLocation = viewState.lastTapLocation {

                let (isSameSide, isLeftSide) = pointsAreSameSide(
                    lastTapLocation,
                    location,
                    width: width,
                    midPadding: viewState.isCompact ? 20 : 50
                )

                if isSameSide {
                    guard viewState.mediaSession?.canSeek == true else { return }

                    isMultiTap = true
                    if !viewState.isTabletop {
                        viewState.hideControls()
                    }

                    if isLeftSide {
                        let interval = Defaults[.VideoPlayer.jumpBackwardInterval]
                        viewState.mediaSession?.seek(by: .zero - (interval.rawValue))

                        viewState.toastProxy.present(
                            Text(
                                interval.rawValue * (jumpProgressObserver.jumps),
                                format: .minuteSecondsNarrow
                            ),
                            systemName: "gobackward"
                        )
                    } else {
                        let interval = Defaults[.VideoPlayer.jumpForwardInterval]
                        viewState.mediaSession?.seek(by: interval.rawValue)

                        viewState.toastProxy.present(
                            Text(
                                interval.rawValue * (jumpProgressObserver.jumps),
                                format: .minuteSecondsNarrow
                            ),
                            systemName: "goforward"
                        )
                    }
                }
            }
        }

        // Respond to the first tap immediately and keep controls hidden during subsequent seek taps.
        if !isMultiTap {
            performSingleTapGesture()
        }

        let side = side(
            of: location,
            width: width,
            midPadding: viewState.isCompact ? 20 : 50
        )

        viewState.lastTapLocation = location

        if side {
            jumpProgressObserver.jumpBackward(interval: 0.35)
        } else {
            jumpProgressObserver.jumpForward(interval: 0.35)
        }
    }

    private func performSingleTapGesture() {
        guard !viewState.isTabletop else { return }

        if viewState.isPresentingSupplement {
            if viewState.isCompact {
                viewState.togglePlaybackButtons()
            } else {
                viewState.selectedSupplementID = nil
            }
        } else {
            viewState.toggleControls()
        }
    }

    private func side(
        of point: CGPoint,
        width: CGFloat,
        midPadding: CGFloat = 50
    ) -> Bool {
        let midX = width / 2
        let leftSide = midX - midPadding

        return point.x < leftSide
    }

    private func pointsAreSameSide(
        _ p1: CGPoint,
        _ p2: CGPoint,
        width: CGFloat,
        midPadding: CGFloat = 50
    ) -> (isSameSide: Bool, isLeftSide: Bool) {
        let p1Side = side(of: p1, width: width, midPadding: midPadding)
        let p2Side = side(of: p2, width: width, midPadding: midPadding)

        return (p1Side == p2Side, p1Side)
    }

    private func handleDoubleTouchGesture(
        location: CGPoint,
        unitPoint: UnitPoint
    ) {
        viewState.cancelTapGesture()
        let action = Defaults[.VideoPlayer.Gesture.doubleTouchGesture]

        switch action {
        case .none:
            ()

        case .aspectFill:
            guard checkGestureLock() else { return }

            viewState.toggleAspectFillBehavior()

        case .gestureLock:
            if viewState.isGestureLocked {
                viewState.isGestureLocked = false

                viewState.toastProxy.present(
                    L10n.gesturesUnlocked,
                    systemName: VideoPlayerActionButton.gestureLock.secondarySystemImage
                )
            } else {
                viewState.isGestureLocked = true

                viewState.toastProxy.present(
                    L10n.gesturesLocked,
                    systemName: VideoPlayerActionButton.gestureLock.systemImage
                )
            }

        case .pausePlay:
            guard checkGestureLock() else { return }

            viewState.mediaSession?.togglePlayPause()
        }
    }

    func handleLongPressGesture(
        location: CGPoint,
        unitPoint: UnitPoint,
        state: UILongPressGestureRecognizer.State
    ) {
        if state == .began {
            viewState.cancelTapGesture()
        }

        guard !viewState.isGestureLocked else {
            guard state == .began else { return }

            viewState.isGestureLocked = false

            viewState.toastProxy.present(
                L10n.gesturesUnlocked,
                systemName: VideoPlayerActionButton.gestureLock.secondarySystemImage
            )

            return
        }

        let action = Defaults[.VideoPlayer.Gesture.longPressAction]

        switch action {
        case .none:
            ()

        case .gestureLock:
            guard state == .began else { return }

            viewState.isGestureLocked = true

            viewState.toastProxy.present(
                L10n.gesturesLocked,
                systemName: VideoPlayerActionButton.gestureLock.systemImage
            )

        case .playbackSpeed:
            guard viewState.mediaSession?.item.isLiveStream == false else { return }

            switch state {
            case .began:
                guard viewState.mediaSession?.canControlPlayback == true else { return }

                viewState.originalPlaybackRate = viewState.mediaSession?.rate

                let multiplier = Defaults[.VideoPlayer.Gesture.longPressSpeedMultiplier]

                viewState.mediaSession?.rate = multiplier.rawValue

                viewState.toastProxy.present(
                    Text(multiplier.displayTitle),
                    systemName: "forward.fill"
                )

            case .ended, .cancelled:
                guard let originalRate = viewState.originalPlaybackRate else { return }

                viewState.mediaSession?.rate = originalRate

                viewState.originalPlaybackRate = nil

                viewState.toastProxy.present(
                    Text(originalRate, format: .playbackRate),
                    systemName: "forward.fill"
                )

            default:
                break
            }
        }
    }
}
