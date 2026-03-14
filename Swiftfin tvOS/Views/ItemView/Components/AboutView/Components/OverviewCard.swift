//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {

    struct OverviewCard: View {

        @Router
        private var router

        let item: BaseItemDto

        var body: some View {
            Card(title: item.displayTitle)
                .content {
                    TruncatedText(item.overview ?? L10n.noOverviewAvailable)
                        .font(.subheadline)
                        .lineLimit(4)
                }
                .onSelect {
                    router.route(to: .itemOverview(item: item))
                }
        }
    }
}
