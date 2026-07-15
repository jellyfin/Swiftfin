//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct CompactPortraitHeaderContentGroup: ContentGroup {

        let id: String = "itemView-header"
        let provider: ItemContentGroupProvider

        func body(with viewModel: Empty) -> Body {
            Body(provider: provider)
        }

        struct Body: View {

            @ObservedObject
            var provider: ItemContentGroupProvider

            @Router
            private var router

            private var hasDescription: Bool {
                provider.item.taglines?.contains(where: \.isNotEmpty) == true ||
                    provider.item.overview?.isNotEmpty == true
            }

            var body: some View {
                VStack(spacing: 10) {
                    VStack(spacing: 10) {
                        HStack(alignment: .bottom, spacing: 12) {
                            PosterImage(
                                item: provider.item,
                                type: .portrait,
                                contentMode: .fit
                            )
                            .frame(width: 130)
                            .posterShadow()

                            Text(provider.item.displayTitle)
                                .font(.title2)
                                .lineLimit(4)
                                .fontWeight(.semibold)
                                .padding(.bottom, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        ItemView.ActionButtonHStack(provider: provider)
                    }
                    .frame(maxWidth: 300)

                    if hasDescription {
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            if let firstTagline = provider.item.taglines?.first(where: \.isNotEmpty) {
                                Text(firstTagline)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.leading)
                            }

                            if let itemOverview = provider.item.overview, itemOverview.isNotEmpty {
                                Button {
                                    router.route(to: .itemOverview(item: provider.item))
                                } label: {
                                    SeeMoreText(itemOverview)
                                        .font(.footnote)
                                        .lineLimit(3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .edgePadding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
