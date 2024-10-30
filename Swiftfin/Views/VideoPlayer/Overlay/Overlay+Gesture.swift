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
        @State
        private var volumePanGestureState: PanGestureState<Float> = .init()

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
        case .volume:
            volumeAction(state: state, point: point)
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
    
//    private func playbackRateAction(
//        state: UIGestureRecognizer.State,
//        point: UnitPoint
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
//    }
    
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
