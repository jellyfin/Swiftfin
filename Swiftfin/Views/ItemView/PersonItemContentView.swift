//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import OrderedCollections
import SwiftUI

extension ItemView {

    struct PersonItemContentView: View {

        typealias Element = OrderedDictionary<BaseItemKind, ItemLibraryViewModel>.Elements.Element

        @Router
        private var router

        @ObservedObject
        var viewModel: PersonItemViewModel

        private func episodeHStack(element: Element) -> some View {
            VStack(alignment: .leading) {

                Text(L10n.episodes)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: [.isHeader])
                    .edgePadding(.horizontal)

                CollectionHStack(
                    uniqueElements: element.value.elements,
                    id: \.unwrappedIDHashOrZero,
                    columns: UIDevice.isPhone ? 1.5 : 3.5
                ) { episode in
                    SeriesEpisodeSelector.EpisodeCard(episode: episode)
                }
                .scrollBehavior(.continuousLeadingEdge)
                .insets(horizontal: EdgeInsets.edgePadding)
                .itemSpacing(EdgeInsets.edgePadding / 2)
            }
        }

        private func posterHStack(element: Element) -> some View {
            PosterHStack(
                title: element.key.pluralDisplayTitle,
                type: .portrait,
                items: element.value.elements
            )
            .trailing {
                SeeAllButton()
                    .onSelect {
                        router.route(to: .library(viewModel: element.value))
                    }
            }
            .onSelect { item in
                router.route(to: .item(item: item))
            }
        }

        var body: some View {
            SeparatorVStack(alignment: .leading) {
                RowDivider()
                    .padding(.vertical, 10)
            } content: {

                // MARK: - Items

                ForEach(
                    viewModel.sections.elements,
                    id: \.key
                ) { element in
                    if element.key == .episode {
                        episodeHStack(element: element)
                    } else {
                        posterHStack(element: element)
                    }
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
