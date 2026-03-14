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
    var longPressAction: LongPressAction? = nil
}

struct LongPressAction {

    let action: (
        _ location: CGPoint,
        _ unitPoint: UnitPoint,
        _ state: UILongPressGestureRecognizer.State
    ) -> Void

    func callAsFunction(
        location: CGPoint,
        unitPoint: UnitPoint,
        state: UILongPressGestureRecognizer.State
    ) {
        action(
            location,
            unitPoint,
            state
        )
    }
}
