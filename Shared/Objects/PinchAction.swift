//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension EnvironmentValues {

    @Entry
    var pinchAction: PinchAction? = nil
}

struct PinchAction {

    let action: (
        _ scale: CGFloat,
        _ velocity: CGFloat,
        _ state: UIGestureRecognizer.State
    ) -> Void

    func callAsFunction(
        scale: CGFloat,
        velocity: CGFloat,
        state: UIGestureRecognizer.State
    ) {
        action(scale, velocity, state)
    }
}
