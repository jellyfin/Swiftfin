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
    var tapGestureAction: TapAction? = nil
}

struct TapAction {

    let action: (
        _ location: CGPoint,
        _ unitPoint: UnitPoint,
        _ count: Int
    ) -> Void

    func callAsFunction(
        location: CGPoint,
        unitPoint: UnitPoint,
        count: Int
    ) {
        action(
            location,
            unitPoint,
            count
        )
    }
}
