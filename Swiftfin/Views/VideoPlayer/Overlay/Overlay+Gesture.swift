//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PanGestureState {
    
    var didStartWithOverlay: Bool = false
    var startSeconds: TimeInterval = 0
    var startPoint: UnitPoint = .zero
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
        private var panGesturestate: PanGestureState = .init()

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
        case .scrub:
            scrubAction(state: state, point: point, velocity: velocity, translation: translation, rate: 1)
        case .slowScrub:
            scrubAction(state: state, point: point, velocity: velocity, translation: translation, rate: 0.1)
        default: ()
        }
    }
}

extension VideoPlayer.Overlay.GestureLayer {
    
    private func scrubAction(
        state: UIGestureRecognizer.State,
        point: UnitPoint,
        velocity: CGFloat,
        translation: CGFloat,
        rate: CGFloat
    ) {
        if state == .began {
            panGesturestate = .init()
            isScrubbing = true
            
            panGesturestate.startSeconds = scrubbedSeconds
            panGesturestate.startPoint = point
        } else if state == .ended {
            isScrubbing = false
            return
        }
        
        let newSeconds = panGesturestate.startSeconds - (panGesturestate.startPoint.x - point.x) * rate * manager.item.runTimeSeconds
        scrubbedSeconds = clamp(newSeconds, min: 0, max: manager.item.runTimeSeconds)
    }
}
