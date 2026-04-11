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
    var panAction: PanAction? = nil
}

struct PanAction {

    let action: (
        _ translation: CGPoint,
        _ velocity: CGPoint,
        _ location: CGPoint,
        _ unitPoint: UnitPoint,
        _ state: UIGestureRecognizer.State
    ) -> Void

    func callAsFunction(
        translation: CGPoint,
        velocity: CGPoint,
        location: CGPoint,
        unitPoint: UnitPoint,
        state: UIGestureRecognizer.State
    ) {
        action(
            translation,
            velocity,
            location,
            unitPoint,
            state
        )
    }
}
