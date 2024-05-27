//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import OrderedCollections
import SwiftUI

// TODO: rename `AboutItemView`
// TODO: see what to do about bottom padding
//       - don't like it adds more than the edge
//       - just have this determine bottom padding
//         instead of scrollviews?

extension OfflineItemView {

    struct AboutView: View {

        private enum AboutViewItem: Hashable {

            case image
            case overview
            case mediaSource(MediaSourceInfo)
            case ratings
        }

        @Default(.accentColor)
        private var accentColor

        @ObservedObject
        var viewModel: OfflineItemViewModel

        @State
        private var contentSize: CGSize = .zero
        @State
        private var items: OrderedSet<AboutViewItem>

        init(viewModel: OfflineItemViewModel) {
            self.viewModel = viewModel

            var items: OrderedSet<AboutViewItem> = [
                .image,
                .overview,
            ]

            if let mediaSources = viewModel.item.mediaSources {
                items.append(contentsOf: mediaSources.map { AboutViewItem.mediaSource($0) })
            }

            if viewModel.item.hasRatings {
                items.append(.ratings)
            }

            self._items = State(initialValue: items)
        }

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

        private var cardSize: CGSize {
            let height = UIDevice.isPad ? padImageWidth * 3 / 2 : phoneImageWidth * 3 / 2
            let width = height * 1.65

            return CGSize(width: width, height: height)
        }

        private var imageView: some View {
            ZStack {
                Color.clear

                ImageView(viewModel.download!.portraitImageSources(maxWidth: 300))
                    .accessibilityIgnoresInvertColors()
            }
            .posterStyle(.portrait)
            .posterShadow()
            .frame(width: UIDevice.isPad ? padImageWidth : phoneImageWidth)
        }

        var body: some View {
            VStack(alignment: .leading) {
                L10n.about.text
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .edgePadding(.horizontal)

                CollectionHStack($items, variadicWidths: true) { item in
                    switch item {
                    case .image:
                        imageView
                    case .overview:
                        OverviewCard(item: viewModel.item)
                            .frame(width: cardSize.width, height: cardSize.height)
                    case let .mediaSource(source):
                        MediaSourcesCard(
                            subtitle: (viewModel.item.mediaSources ?? []).count > 1 ? source.displayTitle : nil,
                            source: source
                        )
                        .frame(width: cardSize.width, height: cardSize.height)
                    case .ratings:
                        RatingsCard(item: viewModel.item)
                            .frame(width: cardSize.width, height: cardSize.height)
                    }
                }
                .clipsToBounds(false)
                .insets(horizontal: EdgeInsets.edgePadding)
                .itemSpacing(EdgeInsets.edgePadding / 2)
                .scrollBehavior(.continuousLeadingEdge)
            }
            .trackingSize($contentSize)
        }
    }
}
