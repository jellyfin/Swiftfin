//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemView {

    struct OverviewView: View {

        @EnvironmentObject
        private var router: ItemCoordinator.Router

        let item: BaseItemDto
        private var overviewLineLimit: Int?
        private var taglineLineLimit: Int?

        var body: some View {
            VStack(alignment: .leading, spacing: 10) {

                if let firstTagline = item.taglines?.first {
                    Text(firstTagline)
                        .font(.body)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(taglineLineLimit)
                }

                if let itemOverview = item.overview {
                    TruncatedText(itemOverview)
                        .onSeeMore {
                            router.route(to: \.itemOverview, item)
                        }
                        .seeMoreType(.view)
                        .font(.footnote)
                        .lineLimit(overviewLineLimit)
                }
            }
        }
    }
}

extension ItemView.OverviewView {

    init(item: BaseItemDto) {
        self.init(
            item: item,
            overviewLineLimit: nil,
            taglineLineLimit: nil
        )
    }

    func overviewLineLimit(_ limit: Int) -> Self {
        copy(modifying: \.overviewLineLimit, with: limit)
    }

    func taglineLineLimit(_ limit: Int) -> Self {
        copy(modifying: \.taglineLineLimit, with: limit)
    }
}
