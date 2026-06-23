//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import JellyfinAPI
import OrderedCollections
import SwiftUI

extension ItemView {

    struct CollectionItemContentView: View {

        typealias Element = OrderedDictionary<BaseItemKind, PagingLibraryViewModel<ItemLibrary>>.Elements.Element

        @Router
        private var router

        @ObservedObject
        var viewModel: CollectionItemViewModel

        // MARK: - Episode Poster HStack

        private func episodeHStack(element: Element) -> some View {
            VStack(alignment: .leading, spacing: 20) {

                HStack {
                    Text(L10n.episodes)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .accessibility(addTraits: [.isHeader])
                        .padding(.leading, 50)

                    Spacer()
                }

                CollectionHStack(
                    uniqueElements: element.value.elements,
                    id: \.id,
                    columns: 3.5
                ) { episode in
                    SeriesEpisodeSelector.EpisodeCard(episode: episode)
                        .padding(.horizontal, 4)
                }
                .scrollBehavior(.continuousLeadingEdge)
                .insets(horizontal: EdgeInsets.edgePadding)
                .itemSpacing(EdgeInsets.edgePadding / 2)
            }
            .focusSection()
        }

        // MARK: - Default Poster Grid

        // Portrait poster columns matching the stock library grid ("TV section": 7-wide on tvOS,
        // see `LibraryElement.layout`). A multi-line `LazyVGrid` (laid out inline in the cinematic
        // ScrollView — no nested scroll) so every title in the collection is reachable, instead of
        // a single horizontal shelf that capped at one page. Trailing items page the next batch in.
        private static let posterColumns = Array(
            repeating: GridItem(.flexible(), spacing: EdgeInsets.edgePadding),
            count: 7
        )

        private func posterGrid(element: Element) -> some View {
            VStack(alignment: .leading, spacing: 20) {
                Text(element.key.pluralDisplayTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .accessibility(addTraits: [.isHeader])
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, EdgeInsets.edgePadding)

                LazyVGrid(columns: Self.posterColumns, spacing: EdgeInsets.edgePadding) {
                    ForEach(element.value.elements, id: \.id) { item in
                        PosterButton(
                            item: item,
                            type: .portrait,
                            action: { router.route(to: .item(item: item)) },
                            label: { PosterButton<BaseItemDto>.TitleSubtitleContentView(item: item) }
                        )
                        .onAppear {
                            if element.value.elements.last?.id == item.id {
                                element.value.getNextPage()
                            }
                        }
                    }
                }
                .padding(.horizontal, EdgeInsets.edgePadding)
            }
            .focusSection()
        }

        var body: some View {
            VStack(spacing: 0) {
                ForEach(
                    viewModel.sections.elements,
                    id: \.key
                ) { element in
                    if element.key == .episode {
                        episodeHStack(element: element)
                    } else {
                        posterGrid(element: element)
                    }
                }

                if viewModel.similarItems.isNotEmpty {
                    ItemView.SimilarItemsHStack(items: viewModel.similarItems)
                }

                ItemView.AboutView(viewModel: viewModel)
            }
        }
    }
}
