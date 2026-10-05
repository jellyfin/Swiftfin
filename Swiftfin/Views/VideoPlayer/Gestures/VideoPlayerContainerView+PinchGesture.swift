//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.UIContainerViewController {

    func handlePinchGesture(
        scale: CGFloat,
        location: CGPoint,
        state: UIGestureRecognizer.State
    ) {
        if state == .began {
            viewState.cancelTapGesture()
        }

        guard checkGestureLock() else { return }
        guard !viewState.isPresentingSupplement else { return }

        let action = Defaults[.VideoPlayer.Gesture.pinchGesture]

        switch action {
        case .none: ()

        case .aspectFill:
            guard state == .ended else { return }

            if scale > 1 {
                viewState.fillVideo()
            } else if scale < 1 {
                viewState.fitVideo()
            }

        case .zoom:
            handleZoomGesture(scale: scale, location: playerLocation(fromControls: location), state: state)
        }
    }

    private func handleZoomGesture(scale: CGFloat, location: CGPoint, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            guard viewState.zoom.beginPinch(
                input: scale,
                location: location,
                fillsViewport: viewState.aspectFillBehavior == .fill
            ) else { return }

            prepareZoomHaptics()
            viewState.setInteraction(.pinch, active: true)

        case .changed:
            guard viewState.zoom.isPinching else { return }

            viewState.zoom.updatePinch(input: scale, location: location)

        case .ended, .cancelled, .failed:
            // Ignore terminal scale/location: after a finger lifts they may no
            // longer describe the last displayed two-finger transform.
            guard viewState.zoom.isPinching else { return }

            withAnimation(.spring(response: 0.3, dampingFraction: 1)) {
                viewState.zoom.endPinch()
            }
            viewState.setInteraction(.pinch, active: false)

        default:
            return
        }
        updateZoomHaptics()
        presentZoomAmount()
    }

    private func presentZoomAmount() {
        guard let transform = viewState.zoom.transform else { return }

        let scale = VideoZoom.displayedScale(transform.scale)
        if scale <= 1.0001 {
            viewState.toastProxy.present(L10n.original)
        } else if let geometry = viewState.zoom.geometry, abs(scale - geometry.fillScale) < 0.0001 {
            viewState.toastProxy.present(L10n.fill)
        } else {
            viewState.toastProxy.present("\(Double(scale).formatted(.number.precision(.fractionLength(1))))×")
        }
    }
}
