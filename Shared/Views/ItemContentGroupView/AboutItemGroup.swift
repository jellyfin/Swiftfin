//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import SwiftUI

struct AboutItemGroup: _ContentGroup {

    let displayTitle: String
    let id: String

    let item: BaseItemDto

    func body(with viewModel: Empty) -> Body {
        Body(item: item)
    }

    struct Body: View {

        private enum AboutViewSection: Identifiable {
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

        @State
        private var contentFrame: CGRect = .zero

        @ArrayBuilder<AboutViewSection>
        private var sections: [AboutViewSection] {
//            .image
            .overview

            if let mediaSources = item.mediaSources {
                mediaSources.map(AboutViewSection.mediaSource)
            }

            if item.hasRatings {
                .ratings
            }
        }

        let item: BaseItemDto

        // TODO: break out into a general solution for general use?
        // use similar math from CollectionHStack
        private var padImageWidth: CGFloat {
            let portraitMinWidth: CGFloat = 140
            let contentWidth = contentFrame.width
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
            let contentWidth = contentFrame.width
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
                Text(L10n.about)
                    .font(.title2)
                    .fontWeight(.bold)
                    .accessibility(addTraits: [.isHeader])
                    .edgePadding(.horizontal)

                CollectionHStack(
                    uniqueElements: sections,
                    variadicWidths: true
                ) { section in
                    switch section {
                    case .image:
//                        ImageCard(viewModel: viewModel)
//                            .frame(width: UIDevice.isPad ? padImageWidth : phoneImageWidth)
                        EmptyView()
                    case .overview:
//                        ItemView.AboutView.OverviewCard(item: item)
//                            .frame(width: cardSize.width, height: cardSize.height)
                        EmptyView()
                    case let .mediaSource(source):
//                        ItemView.AboutView.MediaSourcesCard(
//                            subtitle: (item.mediaSources ?? []).count > 1 ? source.displayTitle : nil,
//                            source: source
//                        )
//                        .frame(width: cardSize.width, height: cardSize.height)
                        EmptyView()
                    case .ratings:
//                        ItemView.AboutView.RatingsCard(item: item)
//                            .frame(width: cardSize.width, height: cardSize.height)
                        EmptyView()
                    }
                }
                .clipsToBounds(false)
                .insets(horizontal: EdgeInsets.edgePadding)
                .itemSpacing(EdgeInsets.edgePadding / 2)
                .scrollBehavior(.continuousLeadingEdge)
            }
            .trackingFrame($contentFrame)
        }
    }
}
