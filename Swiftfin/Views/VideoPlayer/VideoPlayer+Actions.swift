//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: Gestures

// TODO: refactor to be split into other files
// TODO: refactor so that actions are separate from the gesture calculations, so that actions are more general

// extension VideoPlayer {
//
//    private func handlePan(
//        action: PanAction,
//        state: UIGestureRecognizer.State,
//        point: CGFloat,
//        velocity: CGFloat,
//        translation: CGFloat
//    ) {
//        guard !isGestureLocked else { return }
//
//        switch action {
//        case .none:
//            return
//        case .audioffset:
//            audioOffsetAction(state: state, point: point, velocity: velocity, translation: translation)
//        case .brightness:
//            brightnessAction(state: state, point: point, velocity: velocity, translation: translation)
//        case .playbackSpeed:
//            playbackSpeedAction(state: state, point: point, velocity: velocity, translation: translation)
//        case .scrub:
//            scrubAction(state: state, point: point, velocity: velocity, translation: translation, rate: 1)
//        case .slowScrub:
//            scrubAction(state: state, point: point, velocity: velocity, translation: translation, rate: 0.1)
//        case .subtitleOffset:
//            subtitleOffsetAction(state: state, point: point, velocity: velocity, translation: translation)
//        case .volume:
//            volumeAction(state: state, point: point, velocity: velocity, translation: translation)
//        }
//    }
//
//    private func handleHorizontalSwipe(
//        unitPoint: UnitPoint,
//        direction: Bool,
//        amount: Int
//    ) {
//        guard !isGestureLocked else { return }
//
//        switch horizontalSwipeGesture {
//        case .none:
//            return
//        case .jump:
//            jumpAction(unitPoint: .init(x: direction ? 1 : 0, y: 0), amount: amount)
//        }
//    }
//
//    private func handleLongPress(point: UnitPoint) {
//        switch longPressGesture {
//        case .none:
//            return
//        case .gestureLock:
//            guard !isPresentingOverlay else { return }
//            isGestureLocked.toggle()
//        }
//    }
//
//    private func handlePinchGesture(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
//        guard !isGestureLocked else { return }
//
//        switch pinchGesture {
//        case .none:
//            return
//        case .aspectFill:
//            aspectFillAction(state: state, unitPoint: unitPoint, scale: scale)
//        }
//    }
//
//    private func handleTapGesture(unitPoint: UnitPoint, taps: Int) {
//        guard !isGestureLocked else {
//            updateViewProxy.present(systemName: "lock.fill", title: "Gestures Locked")
//            return
//        }
//
//        if taps > 1 && multiTapGesture != .none {
//
//            withAnimation(.linear(duration: 0.1)) {
//                isPresentingOverlay = false
//            }
//
//            switch multiTapGesture {
//            case .none:
//                return
//            case .jump:
//                jumpAction(unitPoint: unitPoint, amount: taps - 1)
//            }
//        } else {
//            withAnimation(.linear(duration: 0.1)) {
//                isPresentingOverlay = !isPresentingOverlay
//            }
//        }
//    }
//
//    private func handleDoubleTouchGesture(unitPoint: UnitPoint, taps: Int) {
//        guard !isGestureLocked else {
//            updateViewProxy.present(systemName: "lock.fill", title: "Gestures Locked")
//            return
//        }
//
//        switch doubleTouchGesture {
//        case .none:
//            return
//        case .aspectFill: ()
//        case .gestureLock:
//            guard !isPresentingOverlay else { return }
//            isGestureLocked.toggle()
//        case .pausePlay: ()
//        }
//    }
// }
//
//// MARK: Actions
//
// extension VideoPlayer {
//
//    private func aspectFillAction(state: UIGestureRecognizer.State, unitPoint: UnitPoint, scale: CGFloat) {
//        guard state == .began || state == .changed else { return }
//        if scale > 1, !isAspectFilled {
//            isAspectFilled = true
//        } else if scale < 1, isAspectFilled {
//            isAspectFilled = false
//        }
//    }
//
//    private func audioOffsetAction(
//        state: UIGestureRecognizer.State,
//        point: CGFloat,
//        velocity: CGFloat,
//        translation: CGFloat
//    ) {
//        if state == .began {
//            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
//            gestureStateHandler.beginningHorizontalPanUnit = point
//            gestureStateHandler.beginningAudioOffset = audioOffset
//        } else if state == .ended {
//            return
//        }
//
//        let newOffset = gestureStateHandler.beginningAudioOffset - round(
//            Int((gestureStateHandler.beginningHorizontalPanUnit - point) * 2000),
//            toNearest: 100
//        )
//
//        updateViewProxy.present(systemName: "speaker.wave.2.fill", title: newOffset.millisecondLabel)
//        audioOffset = clamp(newOffset, min: -30000, max: 30000)
//    }
//
//    private func brightnessAction(
//        state: UIGestureRecognizer.State,
//        point: CGFloat,
//        velocity: CGFloat,
//        translation: CGFloat
//    ) {
//        if state == .began {
//            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
//            gestureStateHandler.beginningHorizontalPanUnit = point
//            gestureStateHandler.beginningBrightnessValue = UIScreen.main.brightness
//        } else if state == .ended {
//            return
//        }
//
//        let newBrightness = gestureStateHandler.beginningBrightnessValue - (gestureStateHandler.beginningHorizontalPanUnit - point)
//        let clampedBrightness = clamp(newBrightness, min: 0, max: 1.0)
//        let flashPercentage = Int(clampedBrightness * 100)
//
//        if flashPercentage >= 67 {
//            updateViewProxy.present(systemName: "sun.max.fill", title: "\(flashPercentage)%", iconSize: .init(width: 30, height: 30))
//        } else if flashPercentage >= 33 {
//            updateViewProxy.present(systemName: "sun.max.fill", title: "\(flashPercentage)%")
//        } else {
//            updateViewProxy.present(systemName: "sun.min.fill", title: "\(flashPercentage)%", iconSize: .init(width: 20, height: 20))
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
//            UIScreen.main.brightness = clampedBrightness
//        }
//    }
//
//    // TODO: decide on overlay behavior?
//    private func jumpAction(
//        unitPoint: UnitPoint,
//        amount: Int
//    ) {
//        if unitPoint.x <= 0.5 {
//            videoPlayerManager.proxy.jumpBackward(Int(jumpBackwardLength.rawValue))
//
//            updateViewProxy.present(systemName: "gobackward", title: "\(amount * Int(jumpBackwardLength.rawValue))s")
//        } else {
//            videoPlayerManager.proxy.jumpForward(Int(jumpForwardLength.rawValue))
//
//            updateViewProxy.present(systemName: "goforward", title: "\(amount * Int(jumpForwardLength.rawValue))s")
//        }
//    }
//
//    private func playbackSpeedAction(
//        state: UIGestureRecognizer.State,
//        point: CGFloat,
//        velocity: CGFloat,
//        translation: CGFloat
//    ) {
//        if state == .began {
//            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
//            gestureStateHandler.beginningHorizontalPanUnit = point
//            gestureStateHandler.beginningPlaybackSpeed = playbackSpeed
//        } else if state == .ended {
//            return
//        }
//
//        let newPlaybackSpeed = round(
//            gestureStateHandler.beginningPlaybackSpeed - Double(gestureStateHandler.beginningHorizontalPanUnit - point) * 2,
//            toNearest: 0.25
//        )
//        let clampedPlaybackSpeed = clamp(newPlaybackSpeed, min: 0.25, max: 5.0)
//
//        updateViewProxy.present(systemName: "speedometer", title: clampedPlaybackSpeed.rateLabel)
//
//        playbackSpeed = clampedPlaybackSpeed
//        vlcUIProxy.setRate(.absolute(Float(clampedPlaybackSpeed)))
//    }
//
//    private func scrubAction(
//        state: UIGestureRecognizer.State,
//        point: CGFloat,
//        velocity: CGFloat,
//        translation: CGFloat,
//        rate: CGFloat
//    ) {
//        if state == .began {
//            isScrubbing = true
//
//            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
//            gestureStateHandler.beginningHorizontalPanUnit = point
//            gestureStateHandler.beganPanWithOverlay = isPresentingOverlay
//        } else if state == .ended {
//            if !gestureStateHandler.beganPanWithOverlay {
//                isPresentingOverlay = false
//            }
//
//            isScrubbing = false
//
//            return
//        }
//
//        let newProgress = gestureStateHandler.beginningPanProgress - (gestureStateHandler.beginningHorizontalPanUnit - point) * rate
//        currentProgressHandler.scrubbedProgress = clamp(newProgress, min: 0, max: 1)
//    }
//
//    private func subtitleOffsetAction(
//        state: UIGestureRecognizer.State,
//        point: CGFloat,
//        velocity: CGFloat,
//        translation: CGFloat
//    ) {
//        if state == .began {
//            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
//            gestureStateHandler.beginningHorizontalPanUnit = point
//            gestureStateHandler.beginningSubtitleOffset = subtitleOffset
//        } else if state == .ended {
//            return
//        }
//
//        let newOffset = gestureStateHandler.beginningSubtitleOffset - round(
//            Int((gestureStateHandler.beginningHorizontalPanUnit - point) * 2000),
//            toNearest: 100
//        )
//        let clampedOffset = clamp(newOffset, min: -30000, max: 30000)
//
//        updateViewProxy.present(systemName: "captions.bubble.fill", title: clampedOffset.millisecondLabel)
//
//        subtitleOffset = clampedOffset
//    }
//
//    private func volumeAction(
//        state: UIGestureRecognizer.State,
//        point: CGFloat,
//        velocity: CGFloat,
//        translation: CGFloat
//    ) {
//        let volumeView = MPVolumeView()
//        guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else { return }
//
//        if state == .began {
//            gestureStateHandler.beginningPanProgress = currentProgressHandler.progress
//            gestureStateHandler.beginningHorizontalPanUnit = point
//            gestureStateHandler.beginningVolumeValue = AVAudioSession.sharedInstance().outputVolume
//        } else if state == .ended {
//            return
//        }
//
//        let newVolume = gestureStateHandler.beginningVolumeValue - Float(gestureStateHandler.beginningHorizontalPanUnit - point)
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
//            slider.value = newVolume
//        }
//    }
// }

extension VideoPlayer {

    class GestureStateHandler {

        var beganPanWithOverlay: Bool = false
        var beginningPanProgress: CGFloat = 0
        var beginningHorizontalPanUnit: CGFloat = 0

        var beginningAudioOffset: Int = 0
        var beginningBrightnessValue: CGFloat = 0
        var beginningPlaybackSpeed: Double = 0
        var beginningSubtitleOffset: Int = 0
        var beginningVolumeValue: Float = 0

        var jumpBackwardKeyPressActive: Bool = false
        var jumpBackwardKeyPressWorkItem: DispatchWorkItem?
        var jumpBackwardKeyPressAmount: Int = 0

        var jumpForwardKeyPressActive: Bool = false
        var jumpForwardKeyPressWorkItem: DispatchWorkItem?
        var jumpForwardKeyPressAmount: Int = 0
    }
}
