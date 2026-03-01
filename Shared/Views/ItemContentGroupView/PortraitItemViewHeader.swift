//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitItemViewHeader: ContentGroup {

    let id = "item-view-header"
    let viewModel: Empty = .init()
    let itemViewModel: ItemViewModel

    func body(with viewModel: Empty) -> Body {
        Body(viewModel: itemViewModel)
    }

    struct Body: View {

        @ObservedObject
        var viewModel: ItemViewModel

        @Router
        private var router

        var body: some View {
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    HStack(alignment: .bottom, spacing: 12) {
                        PosterImage(
                            item: viewModel.item,
                            type: .portrait,
                            contentMode: .fit
                        )
                        .withViewContext(.isOverComplexContent)
                        .frame(width: 130)
                        .accessibilityIgnoresInvertColors()
                        .posterShadow()

                        Text(viewModel.item.displayTitle)
                            .font(.title2)
                            .lineLimit(4)
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ActionButtonHStack(
                        item: viewModel.item,
                        localTrailers: []
                    )
                }
                .frame(maxWidth: 300)

                Divider()

                if let overview = viewModel.item.overview {
                    SeeMoreText(overview) {
                        router.route(to: .itemOverview(item: viewModel.item))
                    }
                    .font(.footnote)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .edgePadding([.bottom, .horizontal])
        }
    }
}
