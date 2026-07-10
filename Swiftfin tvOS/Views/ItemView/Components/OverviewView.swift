//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: have items provide labeled attributes
// TODO: don't layout `VStack` if no data

extension ItemView {

    struct OverviewView: View {

        @Router
        private var router

        let item: BaseItemDto
        private var overviewLineLimit: Int?
        private var taglineLineLimit: Int?

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {

                if let firstTagline = item.taglines?.first {
                    Text(firstTagline)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                        .lineLimit(taglineLineLimit)
                }

                if let itemOverview = item.overview {
                    Button {
                        router.route(to: .itemOverview(item: item))
                    } label: {
                        SeeMoreText(itemOverview)
                            .lineLimit(overviewLineLimit)
                    }
                    .buttonStyle(.plain)
                }
            }
            .font(.footnote)
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
