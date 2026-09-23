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
        velocity: CGFloat,
        state: UIGestureRecognizer.State
    ) {
        guard checkGestureLock() else { return }
        guard !viewState.isPresentingSupplement, state == .ended else { return }

        let action = Defaults[.VideoPlayer.Gesture.pinchGesture]

        switch action {
        case .none: ()
        case .aspectFill:
            if scale > 1 {
                viewState.fillVideo()
            } else if scale < 1 {
                viewState.fitVideo()
            }
        }
    }
}
