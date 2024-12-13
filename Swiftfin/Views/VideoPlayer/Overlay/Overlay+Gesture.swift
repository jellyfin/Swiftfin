//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

        @Environment(\.audioOffset)
        @Binding
        private var audioOffset: TimeInterval

        @Environment(\.isAspectFilled)
        @Binding
        private var isAspectFilled

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
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var toastProxy: ToastProxy

        @State
        private var brightnessPanGestureState: PanGestureState<CGFloat> = .zero
        @State
        private var mediaOffsetPanGestureState: PanGestureState<Double> = .zero
        @State
        private var playbackRatePanGestureState: PanGestureState<Float> = .zero
        @State
        private var scrubPanGestureState: PanGestureState<TimeInterval> = .zero
        @State
        private var volumePanGestureState: PanGestureState<Float> = .zero

        private var isPresentingDrawer: Bool {
            selectedSupplement != nil
        }

        var body: some View {
            GestureView()
                .onHorizontalPan(handlePan)
                .onPinch(handlePinch)
                .onTap(samePointPadding: 10, samePointTimeout: 0.7) { _, _ in
                    if isPresentingDrawer {
                        selectedSupplement = nil
                    } else {
                        isPresentingOverlay.toggle()
                    }
                }
        }
    }
}

extension VideoPlayer.Overlay.GestureLayer {

    private func handlePan(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        velocity: CGFloat,
        translation: CGFloat
    ) {
//        guard !isGestureLocked else { return }

        let action = Defaults[.VideoPlayer.Gesture.panAction]

        switch action {
        case .audioffset: ()
            mediaOffsetAction(state: state, translation: translation, source: _audioOffset.wrappedValue)
        case .brightness:
            brightnessAction(state: state, point: point)
        case .playbackSpeed:
            playbackRateAction(state: state, translation: translation)
        case .scrub:
            scrubAction(state: state, point: point, rate: 1)
        case .slowScrub:
            scrubAction(state: state, point: point, rate: 0.1)
        case .subtitleOffset:
            mediaOffsetAction(state: state, translation: translation, source: _subtitleOffset.wrappedValue)
        case .volume:
            volumeAction(state: state, point: point)
        case .none: ()
        }
    }

    private func handlePinch(
        state: UIGestureRecognizer.State,
        unitPoint: UnitPoint,
        scale: CGFloat
    ) {
//        guard !isGestureLocked else { return }

        let action = Defaults[.VideoPlayer.Gesture.pinchGesture]

        switch action {
        case .aspectFill:
            aspectFillAction(state: state, scale: scale)
        case .none: ()
        }
    }
}

// MARK: - Pan

extension VideoPlayer.Overlay.GestureLayer {

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

    private func brightnessAction(
        state: UIGestureRecognizer.State,
        point: UnitPoint
    ) {
        if state == .began {
            brightnessPanGestureState = .zero
            brightnessPanGestureState.startValue = UIScreen.main.brightness
            brightnessPanGestureState.startPoint = point
        } else if state == .ended {
            return
        }

        let n = brightnessPanGestureState.startValue - (brightnessPanGestureState.startPoint.x - point.x)
        let newBrightness = clamp(n, min: 0, max: 1.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            UIScreen.main.brightness = newBrightness
        }
    }

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
        let clampedRate = clamp(newRate, min: 0.25, max: 5.0)

        manager.set(rate: Float(clampedRate))
    }

    private func scrubAction(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
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

        let newSeconds = scrubPanGestureState.startValue - (scrubPanGestureState.startPoint.x - point.x) * rate * manager.item
            .runTimeSeconds
        scrubbedSeconds = clamp(newSeconds, min: 0, max: manager.item.runTimeSeconds)
    }

    private func volumeAction(
        state: UIGestureRecognizer.State,
        point: UnitPoint
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

        let newVolume = volumePanGestureState.startValue - Float(volumePanGestureState.startPoint.x - point.x)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider.value = clamp(newVolume, min: 0, max: 1)
        }
    }
}

// MARK: - Pinch

extension VideoPlayer.Overlay.GestureLayer {

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
