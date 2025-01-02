//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView.AboutView {

    struct OverviewCard: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        let item: BaseItemDto

        var body: some View {
            Card(title: item.displayTitle, subtitle: item.alternateTitle)
                .content {
                    if let overview = item.overview {
                        TruncatedText(overview)
                            .lineLimit(4)
                            .font(.footnote)
                            .allowsHitTesting(false)
                    } else {
                        L10n.noOverviewAvailable.text
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                .onSelect {
                    router.route(to: \.itemOverview, item)
                }
        }
    }
}
