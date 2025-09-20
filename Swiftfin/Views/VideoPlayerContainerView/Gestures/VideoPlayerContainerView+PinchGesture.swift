//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController {

    func handlePinchGesture(
        scale: CGFloat,
        velocity: CGFloat,
        state: UIGestureRecognizer.State
    ) {
        guard checkGestureLock() else { return }
        guard !containerState.isPresentingSupplement, state != .ended else { return }
        guard state != .ended else { return }

        let action = Defaults[.VideoPlayer.Gesture.pinchGesture]

        switch action {
        case .none: ()
        case .aspectFill:
            if scale > 1, !containerState.isAspectFilled {
                containerState.isAspectFilled = true
            } else if scale < 1, containerState.isAspectFilled {
                containerState.isAspectFilled = false
            }
        }
    }
}
