//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct UnwatchedCountIndicator: View {

    @Default(.Customization.Indicators.showRemainingUnwatched)
    private var showRemainingUnwatched

    let item: BaseItemDto

    var body: some View {
        if showRemainingUnwatched,
           item.type == .series,
           let count = item.userData?.unplayedItemCount,
           count > 0
        {
            NumericBadge(count: count)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }
}

struct NumericBadge: View {

    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(.black.opacity(0.7))

            Text("\(count)")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .frame(width: 20, height: 20)
    }
}
