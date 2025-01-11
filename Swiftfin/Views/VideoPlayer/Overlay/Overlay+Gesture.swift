//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import MediaPlayer
import SwiftUI

extension VideoPlayer.Overlay.GestureLayer {

    struct PanGestureState<Value: BinaryFloatingPoint> {

        var didStartWithOverlay: Bool = false
        var startValue: Value = 0
        var startPoint: UnitPoint = .zero
        var startTranslation: CGFloat = 0

        static var zero: Self {
            .init()
        }
    }
}

extension VideoPlayer.Overlay {

    struct GestureLayer: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @Environment(\.audioOffset)
        @Binding
        private var audioOffset: TimeInterval

        @Environment(\.isAspectFilled)
        @Binding
        private var isAspectFilled

        @Environment(\.isGestureLocked)
        @Binding
        private var isGestureLocked

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @Environment(\.selectedMediaPlayerSupplement)
        @Binding
        private var selectedSupplement: AnyMediaPlayerSupplement?

        @Environment(\.scrubbedSeconds)
        @Binding
        private var scrubbedSeconds: TimeInterval

        @Environment(\.subtitleOffset)
        @Binding
        private var subtitleOffset: TimeInterval

        @EnvironmentObject
        private var jumpProgressObserver: JumpProgressObserver
        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var toastProxy: ToastProxy

        // MARK: - States

        @State
        private var brightnessPanGestureState: PanGestureState<CGFloat> = .zero
        @State
        private var mediaOffsetPanGestureState: PanGestureState<TimeInterval> = .zero
        @State
        private var playbackRatePanGestureState: PanGestureState<Float> = .zero
        @State
        private var scrubPanGestureState: PanGestureState<TimeInterval> = .zero
        @State
        private var volumePanGestureState: PanGestureState<Float> = .zero

        private var isPresentingDrawer: Bool {
            selectedSupplement != nil
        }

        // MARK: - body

        var body: some View {
            GestureView()
//                .onDoubleTouch TODO: implement
                    .onHorizontalPan(handleHorizontalPan)
                    .onHorizontalSwipe(translation: 100, velocity: 1500, sameSwipeDirectionTimeout: 1, handleHorizontalSwipe)
                    .onLongPress(minimumDuration: 1, handleLongPress)
                    .onPinch(handlePinch)
                    .onTap(samePointPadding: 10, samePointTimeout: 0.7) { _, _ in
                        guard checkGestureLock() else { return }

                        if isPresentingDrawer {
                            selectedSupplement = nil
                        } else {
                            isPresentingOverlay.toggle()
                        }
                    }
                    .onVerticalPan(handleVerticalPan)
        }
    }
}

// MARK: - Handle

extension VideoPlayer.Overlay.GestureLayer {

    private func checkGestureLock() -> Bool {
        if isGestureLocked {
            toastProxy.present("Gesture lock", systemName: "lock.fill")
            return false
        }

        return true
    }

    private func handleLongPress(point: UnitPoint) {
        let action = Defaults[.VideoPlayer.Gesture.longPressAction]

        switch action {
        case .none:
            return
        case .gestureLock:
            guard !isPresentingOverlay else { return }
            isGestureLocked.toggle()
        }
    }

    private func handleHorizontalPan(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        guard checkGestureLock() else { return }

        _handlePan(
            action: Defaults[.VideoPlayer.Gesture.horizontalPanAction],
            state: state,
            point: point,
            pointComponent: \.x,
            velocity: velocity,
            translation: translation
        )
    }

    private func handleVerticalPan(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        guard checkGestureLock() else { return }

        let action: PanAction = if point.x <= 0.5 {
            Defaults[.VideoPlayer.Gesture.verticalPanLeftAction]
        } else {
            Defaults[.VideoPlayer.Gesture.verticalPanRightAction]
        }

        // Invert point for "up == +, down == -"
        _handlePan(
            action: action,
            state: state,
            point: point.inverted,
            pointComponent: \.y,
            velocity: velocity,
            translation: translation
        )
    }

    private func _handlePan(
        action: PanAction,
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        pointComponent: KeyPath<UnitPoint, CGFloat>,
        velocity: CGFloat,
        translation: CGFloat
    ) {
        switch action {
        case .none: ()
        case .audioffset:
            mediaOffsetAction(
                state: state,
                translation: translation,
                source: _audioOffset.wrappedValue
            )
        case .brightness:
            brightnessAction(
                state: state,
                point: point,
                pointComponent: pointComponent
            )
        case .playbackSpeed:
            playbackRateAction(
                state: state,
                translation: translation
            )
        case .scrub:
            scrubAction(
                state: state,
                point: point,
                pointComponent: pointComponent,
                rate: 1
            )
        case .slowScrub:
            scrubAction(
                state: state,
                point: point,
                pointComponent: pointComponent,
                rate: 0.1
            )
        case .subtitleOffset:
            mediaOffsetAction(
                state: state,
                translation: translation,
                source: _subtitleOffset.wrappedValue
            )
        case .volume:
            volumeAction(
                state: state,
                point: point,
                pointComponent: pointComponent
            )
        }
    }

    private func handleHorizontalSwipe(
        point: UnitPoint,
        direction: Direction
    ) {
        guard checkGestureLock() else { return }

        let action = Defaults[.VideoPlayer.Gesture.horizontalSwipeAction]

        switch action {
        case .none: ()
        case .jump:
            jumpAction(point: point, direction: direction)
        }
    }

    private func handlePinch(
        state: UIGestureRecognizer.State,
        unitPoint: UnitPoint,
        scale: CGFloat
    ) {
        guard checkGestureLock() else { return }

        let action = Defaults[.VideoPlayer.Gesture.pinchGesture]

        switch action {
        case .aspectFill:
            aspectFillAction(state: state, scale: scale)
        case .none: ()
        }
    }
}

// MARK: - Long press

extension VideoPlayer.Overlay.GestureLayer {}

// MARK: - Pan

extension VideoPlayer.Overlay.GestureLayer {

    // MARK: - Offset

    private func mediaOffsetAction(
        state: UIGestureRecognizer.State,
        translation: CGFloat,
        source: Binding<TimeInterval>
    ) {
        if state == .began {
            mediaOffsetPanGestureState = .zero
            mediaOffsetPanGestureState.startValue = source.wrappedValue
            mediaOffsetPanGestureState.startTranslation = translation
        } else if state == .ended {
            return
        }

        let newOffset = round(
            (mediaOffsetPanGestureState.startTranslation - translation) * 0.1,
            toNearest: 0.1
        )

        source.wrappedValue = clamp(newOffset, min: -30, max: 30)

        print(source.wrappedValue)

//        toastProxy.present(
//            Text(
//                source.wrappedValue,
//                format: .interval(style: .abbreviated, fields: [.second])
//            ),
//            systemName: "heart.fill"
//        )
    }

    // MARK: - Brightness

    private func brightnessAction(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        pointComponent: KeyPath<UnitPoint, CGFloat>
    ) {
        if state == .began {
            brightnessPanGestureState = .zero
            brightnessPanGestureState.startValue = UIScreen.main.brightness
            brightnessPanGestureState.startPoint = point
        } else if state == .ended {
            return
        }

        let n = brightnessPanGestureState
            .startValue - (brightnessPanGestureState.startPoint[keyPath: pointComponent] - point[keyPath: pointComponent])
        let newBrightness = clamp(n, min: 0, max: 1.0)

        toastProxy.present(
            Text(newBrightness, format: .percent.precision(.fractionLength(0))),
            systemName: "sun.max.fill"
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            UIScreen.main.brightness = newBrightness
        }
    }

    // MARK: - Playback Rate

    private func playbackRateAction(
        state: UIGestureRecognizer.State,
        translation: CGFloat
    ) {
        if state == .began {
            playbackRatePanGestureState = .zero
            playbackRatePanGestureState.startValue = manager.rate
            playbackRatePanGestureState.startTranslation = translation
        } else if state == .ended {
            return
        }

        let newRate = round(
            abs(playbackRatePanGestureState.startTranslation - translation) * 2,
            toNearest: 0.25
        )
        let clampedRate = Float(clamp(newRate, min: 0.25, max: 5.0))

        manager.set(rate: clampedRate)

        toastProxy.present(
            Text(clampedRate, format: .playbackRate),
            systemName: "speedometer"
        )
    }

    // MARK: - Scrub

    private func scrubAction(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        pointComponent: KeyPath<UnitPoint, CGFloat>,
        rate: CGFloat
    ) {
        if state == .began {
            scrubPanGestureState = .zero
            scrubPanGestureState.startValue = scrubbedSeconds
            scrubPanGestureState.startPoint = point

            isScrubbing = true
        } else if state == .ended {
            isScrubbing = false
            return
        }

        let newSeconds = scrubPanGestureState
            .startValue - (scrubPanGestureState.startPoint[keyPath: pointComponent] - point[keyPath: pointComponent]) * rate * manager.item
            .runTimeSeconds
        scrubbedSeconds = clamp(newSeconds, min: 0, max: manager.item.runTimeSeconds)
    }

    // MARK: - Volume

    private func volumeAction(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        pointComponent: KeyPath<UnitPoint, CGFloat>
    ) {
        guard let slider = MPVolumeView()
            .subviews
            .first(where: { $0 is UISlider }) as? UISlider else { return }

        if state == .began {
            volumePanGestureState = .zero
            volumePanGestureState.startValue = AVAudioSession.sharedInstance().outputVolume
            volumePanGestureState.startPoint = point
        } else if state == .ended {
            return
        }

        let newVolume = volumePanGestureState
            .startValue - Float(volumePanGestureState.startPoint[keyPath: pointComponent] - point[keyPath: pointComponent])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider.value = clamp(newVolume, min: 0, max: 1)
        }
    }
}

// MARK: - Pinch

extension VideoPlayer.Overlay.GestureLayer {

    // MARK: - Aspect Fill

    private func aspectFillAction(
        state: UIGestureRecognizer.State,
        scale: CGFloat
    ) {
        guard state == .began || state == .ended else { return }

        if scale > 1, !isAspectFilled {
            isAspectFilled = true
        } else if scale < 1, isAspectFilled {
            isAspectFilled = false
        }
    }
}

// MARK: - Swipe

extension VideoPlayer.Overlay.GestureLayer {

    private func jumpAction(point: UnitPoint, direction: Direction) {
        switch direction {
        case .left:
            jumpProgressObserver.jumpBackward()
            manager.proxy?.jumpBackward(jumpBackwardInterval.interval)

            toastProxy.present(
                Text(Double(jumpProgressObserver.jumps) * jumpBackwardInterval.interval, format: .minuteSeconds),
                systemName: "gobackward"
            )
        case .right:
            jumpProgressObserver.jumpForward()
            manager.proxy?.jumpForward(jumpForwardInterval.interval)

            toastProxy.present(
                Text(Double(jumpProgressObserver.jumps) * jumpForwardInterval.interval, format: .minuteSeconds),
                systemName: "goforward"
            )
        default: ()
        }
    }
}
