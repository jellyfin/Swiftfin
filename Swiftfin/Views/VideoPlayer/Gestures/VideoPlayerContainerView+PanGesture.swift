//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import MediaPlayer
import SwiftUI
import UIKit

extension VideoPlayer.UIContainerViewController {

    func handlePanGesture(
        translation: CGPoint,
        velocity: CGPoint,
        location: CGPoint,
        unitPoint: UnitPoint,
        state: UIGestureRecognizer.State
    ) {
        guard checkGestureLock() else { return }

        if state == .began {
            viewState.setInteraction(.pan, active: true)
        }

        if state == .ended || state == .cancelled || state == .failed {
            viewState.setInteraction(.pan, active: false)
        }

        if viewState.isPresentingSupplement {
            handleSupplementPanAction(
                translation: translation,
                velocity: velocity.y,
                location: location,
                state: state
            )

            return
        }

        let direction: Direction = {
            // Prioritize horizontal detection just a bit more
            if velocity.y.magnitude < velocity.x.magnitude + 20 {
                return velocity.x > 0 ? .right : .left
            }
            return velocity.y > 0 ? .down : .up
        }()

        let handlingState: _PanHandlingState = .init(
            translation: translation,
            velocity: velocity,
            location: location,
            unitPoint: unitPoint,
            gestureState: state
        )

        if Defaults[.VideoPlayer.Gesture.horizontalSwipeAction] != .none, direction.isHorizontal {
            if !viewState.didSwipe,
               max(velocity.x.magnitude, velocity.y.magnitude) >= 1200,
               max(translation.x.magnitude, translation.y.magnitude) >= 80
            {
                handleSwipeAction(direction: direction)
                viewState.didSwipe = true
            }

            if state == .ended {
                viewState.didSwipe = false
            }

            return
        }

        if state == .began {
            let newAction = makePanHandlingAction(
                direction: direction,
                location: location,
                unitPoint: unitPoint
            )

            viewState.panHandlingAction = newAction
        }

        if let currentAction = viewState.panHandlingAction {
            unpackAndHandlePan(
                handlingState: handlingState,
                action: currentAction
            )
        }

        guard state != .ended, state != .cancelled, state != .failed else {
            viewState.panHandlingAction = nil
            return
        }
    }

    private func unpackAndHandlePan(
        handlingState: _PanHandlingState,
        action: some _PanHandlingAction
    ) {
        action.onChange(
            action.startState,
            handlingState,
            viewState
        )
    }

    private func makePanHandlingAction(
        direction: Direction,
        location: CGPoint,
        unitPoint: UnitPoint
    ) -> any _PanHandlingAction {
        let newAction: any _PanHandlingAction = {
            if viewState.isPresentingControls {
                Self.SupplementPanHandlingAction
            } else if direction.isVertical {
                if unitPoint.x < 0.5 {
                    panActionForGestureAction(
                        for: Defaults[.VideoPlayer.Gesture.verticalPanLeftAction]
                    )
                } else {
                    panActionForGestureAction(
                        for: Defaults[.VideoPlayer.Gesture.verticalPanRightAction]
                    )
                }
            } else {
                panActionForGestureAction(
                    for: Defaults[.VideoPlayer.Gesture.horizontalPanAction]
                )
            }
        }()

        func unpackAndSetStartState<Handler: _PanHandlingAction>(
            action: Handler
        ) -> Handler {
            var action = action
            action.startState = _PanStartHandlingState(
                direction: direction,
                location: location,
                value: action.startValue(viewState)
            )
            return action
        }

        return unpackAndSetStartState(action: newAction)
    }

    private func panActionForGestureAction(for gestureAction: PanGestureAction) -> any _PanHandlingAction {
        let isLiveStream = viewState.manager?.item.isLiveStream == true

        switch (gestureAction, isLiveStream) {
        case (.none, _), (.scrub, true), (.slowScrub, true):
            return Self.SupplementPanHandlingAction
        case (.brightness, _):
            return Self.BrightnessPanHandlingAction
        case (.scrub, false):
            return Self.ScrubPanHandlingAction()
        case (.slowScrub, false):
            return Self.ScrubPanHandlingAction(damping: 0.1)
        case (.volume, _):
            return Self.VolumePanHandlingAction
        }
    }

    private func handleSwipeAction(direction: Direction) {
        guard viewState.manager?.item.isLiveStream == false else { return }
        let jumpProgressObserver = viewState.jumpProgressObserver
        viewState.showProgress()

        if direction == .left {
            let interval = Defaults[.VideoPlayer.jumpBackwardInterval]
            viewState.manager?.proxy?.jumpBackward(interval.rawValue)
            jumpProgressObserver.jumpBackward()

            viewState.toastProxy.present(
                Text(
                    interval.rawValue * jumpProgressObserver.jumps,
                    format: .minuteSecondsNarrow
                ),
                systemName: "gobackward"
            )
        } else if direction == .right {
            let interval = Defaults[.VideoPlayer.jumpForwardInterval]
            viewState.manager?.proxy?.jumpForward(interval.rawValue)
            jumpProgressObserver.jumpForward()

            viewState.toastProxy.present(
                Text(
                    interval.rawValue * jumpProgressObserver.jumps,
                    format: .minuteSecondsNarrow
                ),
                systemName: "goforward"
            )
        }
    }
}

// MARK: - Pan actions

extension VideoPlayer.UIContainerViewController {

    // MARK: - Brightness

    private static var BrightnessPanHandlingAction: PanHandlingAction<CGFloat> {
        PanHandlingAction<CGFloat>(
            startValue: UIScreen.main.brightness
        ) { startState, handlingState, viewState in
            guard handlingState.gestureState != .ended else { return }

            let translation: CGFloat = {
                if startState.direction.isHorizontal {
                    handlingState.translation.x
                } else {
                    -handlingState.translation.y
                }
            }()

            let newBrightness = clamp(
                startState.value + CGFloat(translation / 300),
                min: 0,
                max: 1
            )

            viewState.toastProxy.present(
                Text(newBrightness, format: .percent.precision(.fractionLength(0))),
                systemName: "sun.max.fill"
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                UIScreen.main.brightness = newBrightness
            }
        }
    }

    // MARK: - Scrub

    private static func ScrubPanHandlingAction(
        damping: CGFloat = 1
    ) -> PanHandlingAction<Duration> {
        PanHandlingAction<Duration>(
            startValue: { viewState in
                viewState.scrubbedSeconds.value
            }
        ) { startState, handlingState, viewState in
            if handlingState.gestureState == .ended ||
                handlingState.gestureState == .cancelled ||
                handlingState.gestureState == .failed
            {
                viewState.isScrubbing = false

                return
            }

            guard let runtime = viewState.manager?.item.runtime else { return }

            let translation: CGFloat = {
                if startState.direction.isHorizontal {
                    handlingState.translation.x
                } else {
                    -handlingState.translation.y
                }
            }()
            let totalSize: CGFloat = {
                if startState.direction.isHorizontal {
                    handlingState.location.x / handlingState.unitPoint.x
                } else {
                    handlingState.location.y / handlingState.unitPoint.y
                }
            }()

            viewState.isScrubbing = true

            let newSeconds = clamp(
                startState.value.seconds + (translation / totalSize) * runtime.seconds * damping,
                min: 0,
                max: runtime.seconds
            )

            let newSecondsDuration = Duration.seconds(newSeconds)

            viewState.scrubbedSeconds.value = newSecondsDuration
        }
    }

    // MARK: - Supplement

    private static var SupplementPanHandlingAction: PanHandlingAction<CGFloat> {
        PanHandlingAction<CGFloat>(
            startValue: 0
        ) { _, handlingState, viewState in
            viewState.containerView?.handleSupplementPanAction(
                translation: handlingState.translation,
                velocity: handlingState.velocity.y,
                location: handlingState.location,
                state: handlingState.gestureState
            )
        }
    }

    // MARK: - Volume

    private static var VolumePanHandlingAction: PanHandlingAction<Float> {
        PanHandlingAction<Float>(
            startValue: AVAudioSession.sharedInstance().outputVolume
        ) { startState, handlingState, _ in
            guard handlingState.gestureState != .ended else { return }

            guard let slider = MPVolumeView()
                .subviews
                .first(where: { $0 is UISlider }) as? UISlider else { return }
            let translation: CGFloat = {
                if startState.direction.isHorizontal {
                    handlingState.translation.x
                } else {
                    -handlingState.translation.y
                }
            }()

            let newVolume = clamp(
                startState.value + Float(translation / 300),
                min: 0,
                max: 1
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                slider.value = newVolume
            }
        }
    }
}
