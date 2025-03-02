//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

// TODO: rename `AboutItemView`
// TODO: see what to do about bottom padding
//       - don't like it adds more than the edge
//       - just have this determine bottom padding
//         instead of scrollviews?

extension ItemView {

    struct AboutView: View {

        private enum AboutViewItem: Identifiable {
            case image
            case overview
            case mediaSource(MediaSourceInfo)
            case ratings

            var id: String? {
                switch self {
                case .image:
                    return "image"
                case .overview:
                    return "overview"
                case let .mediaSource(source):
                    return source.id
                case .ratings:
                    return "ratings"
                }
            }
        }

        @ObservedObject
        var viewModel: ItemViewModel

        @State
        private var contentSize: CGSize = .zero

        private var items: [AboutViewItem] {
            var items: [AboutViewItem] = [
                .image,
                .overview,
            ]

            if let mediaSources = viewModel.item.mediaSources {
                items.append(contentsOf: mediaSources.map { AboutViewItem.mediaSource($0) })
            }

            if viewModel.item.hasRatings {
                items.append(.ratings)
            }

            return items
        }

        init(viewModel: ItemViewModel) {
            self.viewModel = viewModel
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

        var body: some View {
            VStack(alignment: .leading) {
                L10n.about.text
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .edgePadding(.horizontal)

                CollectionHStack(
                    uniqueElements: items,
                    variadicWidths: true
                ) { item in
                    switch item {
                    case .image:
                        ImageCard(viewModel: viewModel)
                            .frame(width: UIDevice.isPad ? padImageWidth : phoneImageWidth)
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
            .id(viewModel.item.hashValue)
        }
    }
}
