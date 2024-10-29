//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.GestureLayer {
    
    struct PanGestureState<Value: BinaryFloatingPoint> {
        
        var didStartWithOverlay: Bool = false
        var startValue: Value = 0
        var startPoint: UnitPoint = .zero
        
        static var zero: Self {
            .init()
        }
    }
}

extension VideoPlayer.Overlay {
    
    struct GestureLayer: View {
        
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.selectedMediaPlayerSupplement)
        @Binding
        private var selectedSupplement: AnyMediaPlayerSupplement?
        @Environment(\.scrubbedSeconds)
        @Binding
        private var scrubbedSeconds: TimeInterval
        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        
        @EnvironmentObject
        private var manager: MediaPlayerManager
        
        @State
        private var brightnessPanGestureState: PanGestureState<CGFloat> = .init()
        @State
        private var scrubPanGestureState: PanGestureState<TimeInterval> = .init()

        @StateObject
        private var overlayTimer: PokeIntervalTimer = .init()
        
        private var isPresentingDrawer: Bool {
            selectedSupplement != nil
        }
        
        var body: some View {
            GestureView()
                .onHorizontalPan(handlePan)
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
        
        let action = Defaults[.VideoPlayer.Gesture.panAction]
        
        switch action {
        case .brightness:
            brightnessAction(state: state, point: point)
        case .scrub:
            scrubAction(state: state, point: point, rate: 1)
        case .slowScrub:
            scrubAction(state: state, point: point, rate: 0.1)
        default: ()
        }
    }
}

extension VideoPlayer.Overlay.GestureLayer {
    
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
        
        let newSeconds = scrubPanGestureState.startValue - (scrubPanGestureState.startPoint.x - point.x) * rate * manager.item.runTimeSeconds
        scrubbedSeconds = clamp(newSeconds, min: 0, max: manager.item.runTimeSeconds)
    }
}

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
