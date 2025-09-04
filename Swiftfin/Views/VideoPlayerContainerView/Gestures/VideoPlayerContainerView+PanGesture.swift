//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension UIVideoPlayerContainerViewController {

    func handlePanGesture(
        translation: CGPoint,
        velocity: CGFloat,
        location: CGPoint,
        state: UIGestureRecognizer.State
    ) {
        handleSupplementPanAction(
            translation: translation,
            velocity: velocity,
            location: location,
            state: state
        )
    }
}
