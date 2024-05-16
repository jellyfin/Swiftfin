//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: rename `AboutItemView`
// TODO: see what to do about bottom padding
//       - don't like it adds more than the edge
//       - just have this determine bottom padding
//         instead of scrollviews?

extension ItemView {

    struct AboutView: View {

        @Default(.accentColor)
        private var accentColor

        @ObservedObject
        var viewModel: ItemViewModel

        @State
        private var contentSize: CGSize = .zero

        // TODO: break out into a general solution for general use?
        // use similar math from CollectionHStack
        private var padImageWidth: CGFloat {
            let portraitMinWidth: CGFloat = 140
            let contentWidth = contentSize.width
            let usableWidth = contentWidth - EdgeInsets.edgePadding * 2
            var columns = CGFloat(Int(usableWidth / portraitMinWidth))
            let preItemSpacing = (columns - 1) * (EdgeInsets.edgePadding / 2)
            let preTotalNegative = EdgeInsets.edgePadding * 2 + preItemSpacing

            if columns * portraitMinWidth + preTotalNegative > contentWidth {
                columns -= 1
            }

            let itemSpacing = (columns - 1) * (EdgeInsets.edgePadding / 2)
            let totalNegative = EdgeInsets.edgePadding * 2 + itemSpacing
            let itemWidth = (contentWidth - totalNegative) / columns

            return max(0, itemWidth)
        }

        private var phoneImageWidth: CGFloat {
            let contentWidth = contentSize.width
            let usableWidth = contentWidth - EdgeInsets.edgePadding * 2
            let itemSpacing = (EdgeInsets.edgePadding / 2) * 2
            let itemWidth = (usableWidth - itemSpacing) / 3

            return max(0, itemWidth)
        }

        var body: some View {
            VStack(alignment: .leading) {
                L10n.about.text
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .edgePadding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: EdgeInsets.edgePadding / 2) {
                        ZStack {
                            Color.clear

                            ImageView(
                                viewModel.item.type == .episode ? viewModel.item.seriesImageSource(.primary, maxWidth: 300) : viewModel
                                    .item.imageSource(.primary, maxWidth: 300)
                            )
                            .accessibilityIgnoresInvertColors()
                        }
                        .posterStyle(.portrait, contentMode: .fit)
                        .posterShadow()
                        .frame(width: UIDevice.isPad ? padImageWidth : phoneImageWidth)

                        OverviewCard(item: viewModel.item)

                        if let mediaSources = viewModel.item.mediaSources {
                            ForEach(mediaSources) { source in
                                MediaSourcesCard(subtitle: mediaSources.count > 1 ? source.displayTitle : nil, source: source)
                            }
                        }

                        RatingsCard(item: viewModel.item)
                    }
                    .edgePadding(.horizontal)
                    .padding(.bottom)
                }
            }
            .trackingSize($contentSize)
        }
    }
}
