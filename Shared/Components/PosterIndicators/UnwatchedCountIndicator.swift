//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI


struct UnwatchedCountIndicator: View {

    @Default(.Customization.Indicators.showRemainingUnwatched)
    private var showRemainingUnwatched

    let item: BaseItemDto

    var body: some View {
        if showRemainingUnwatched,
           item.type == .series,
           let count = item.userData?.unwatchedItemCount,
           count > 0 {
            AttributeBadge {
                Text(String(count))
            }
            .foregroundStyle(.white, .black.opacity(0.8))
        }
    }
}
