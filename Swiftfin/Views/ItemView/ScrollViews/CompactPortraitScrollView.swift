//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct CompactPortraitScrollView: View {

        @ObservedObject
        var provider: ItemContentGroupProvider
        @ObservedObject
        var viewModel: ContentGroupViewModel<ItemContentGroupProvider>

        @Router
        private var router

        @ViewBuilder
        private var header: some View {
            VStack(spacing: 10) {
                VStack(spacing: 10) {
                    HStack(alignment: .bottom, spacing: 12) {
                        PosterImage(
                            item: provider.item,
                            type: .portrait,
                            contentMode: .fit
                        )
                        .withViewContext(.isOverComplexContent)
                        .frame(width: 130)
                        .accessibilityIgnoresInvertColors()
                        .posterShadow()

                        Text(provider.item.displayTitle)
                            .font(.title2)
                            .lineLimit(4)
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    ItemView.ActionButtonHStack(provider: provider)
                        .frame(height: 50)
                }
                .frame(maxWidth: 300)

                Divider()

                ItemView.OverviewView(item: provider.item)
                    .overviewLineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .edgePadding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }

        var body: some View {
            BlurredNavigationBarScrollView(usesOffsetNavigationBar: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    ContentGroupVStack(groups: viewModel.groups)
                }
                .edgePadding(.bottom)
            }
        }
    }
}
