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

    func handleTapGestureInSupplement(
        location: CGPoint,
        unitPoint: UnitPoint,
        count: Int
    ) {
        guard !viewState.isPresentingSupplement else { return }

        handleTapGesture(
            location: location,
            unitPoint: unitPoint,
            count: count
        )
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
        if viewState.isPresentingSupplement {
            if viewState.isCompact {
                viewState.togglePlaybackButtons()
            } else {
                viewState.selectedSupplementID = nil
            }
        } else {
            viewState.toggleControls()
        }

        let action = Defaults[.VideoPlayer.Gesture.multiTapGesture]
        let jumpProgressObserver = viewState.jumpProgressObserver
        let width = location.x / unitPoint.x

        switch action {
        case .none: ()
        case .jump:
            guard viewState.manager?.item.isLiveStream == false else { return }

            if let lastTapLocation = viewState.lastTapLocation {

                let (isSameSide, isLeftSide) = pointsAreSameSide(
                    lastTapLocation,
                    location,
                    width: width,
                    midPadding: viewState.isCompact ? 20 : 50
                )

                if isSameSide {

                    viewState.showProgress(keepingControls: false)

                    if isLeftSide {
                        let interval = Defaults[.VideoPlayer.jumpBackwardInterval]
                        viewState.manager?.proxy?.jumpBackward(interval.rawValue)

                        viewState.toastProxy.present(
                            Text(
                                interval.rawValue * (jumpProgressObserver.jumps),
                                format: .minuteSecondsNarrow
                            ),
                            systemName: "gobackward"
                        )
                    } else {
                        let interval = Defaults[.VideoPlayer.jumpForwardInterval]
                        viewState.manager?.proxy?.jumpForward(interval.rawValue)

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
        let action = Defaults[.VideoPlayer.Gesture.doubleTouchGesture]

        switch action {
        case .none: ()
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
            viewState.manager?.togglePlayPause()
        }
    }

    func handleLongPressGesture(
        location: CGPoint,
        unitPoint: UnitPoint,
        state: UILongPressGestureRecognizer.State
    ) {
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
        case .none: ()
        case .gestureLock:
            guard state == .began else { return }

            viewState.isGestureLocked = true

            viewState.toastProxy.present(
                L10n.gesturesLocked,
                systemName: VideoPlayerActionButton.gestureLock.systemImage
            )
        case .playbackSpeed:
            guard viewState.manager?.item.isLiveStream == false else { return }

            switch state {
            case .began:
                viewState.originalPlaybackRate = viewState.manager?.rate

                let multiplier = Defaults[.VideoPlayer.Gesture.longPressSpeedMultiplier]

                viewState.manager?.setRate(rate: multiplier.rawValue)

                viewState.toastProxy.present(
                    Text(multiplier.displayTitle),
                    systemName: "forward.fill"
                )

            case .ended, .cancelled:
                guard let originalRate = viewState.originalPlaybackRate else { return }
                viewState.manager?.setRate(rate: originalRate)

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
