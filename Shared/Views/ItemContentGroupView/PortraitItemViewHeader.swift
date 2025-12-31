//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct PortraitItemViewHeader: _ContentGroup {

    let id = "item-view-header"
    let viewModel: Empty = .init()
    let itemViewModel: _ItemViewModel

    func body(with viewModel: Empty) -> Body {
        Body(viewModel: itemViewModel)
    }

    struct Body: View {

        @ObservedObject
        var viewModel: _ItemViewModel

        @ViewBuilder
        private var overlay: some View {
            HStack(alignment: .bottom, spacing: 12) {
                PosterImage(
                    item: viewModel.item,
                    type: .portrait,
                    contentMode: .fit
                )
                .withViewContext(.isOverComplexContent)
                .frame(width: 130)
                .accessibilityIgnoresInvertColors()

                Text(viewModel.item.displayTitle)
                    .font(.title2)
                    .lineLimit(2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.bottom, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .edgePadding(.bottom)
            .background(
                alignment: .bottom,
                extendedBy: .init(vertical: 25, horizontal: EdgeInsets.edgePadding)
            ) {
                Rectangle()
                    .fill(Material.ultraThin)
                    .maskLinearGradient {
                        (location: 0, opacity: 0)
                        (location: 0.1, opacity: 0.7)
                        (location: 0.2, opacity: 1)
                    }
            }
        }

        var body: some View {
            VStack {
                overlay
                    .edgePadding(.horizontal)
                    .frame(maxWidth: .infinity)
                    .colorScheme(.dark)
            }
            .backgroundParallaxHeader(
                multiplier: 0.3
            ) {
                AlternateLayoutView {
                    Color.clear
                } content: {
                    ImageView(
                        viewModel.item.landscapeImageSources(maxWidth: 1320, environment: .init(useParent: false))
                    )
                    .aspectRatio(contentMode: .fit)
                }
                .aspectRatio(1.77, contentMode: .fit)
            }
            .scrollViewHeaderOffsetOpacity()
            .trackingFrame(for: .scrollViewHeader, key: ScrollViewHeaderFrameKey.self)
            .preference(key: _ContentGroupCustomizationKey.self, value: .useOffsetNavigationBar)
        }
    }
}
