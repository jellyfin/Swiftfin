//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct SearchView: View {

    @Default(.Customization.searchPosterType)
    private var searchPosterType

    @Default(.Customization.Filters.searchFilterDrawerButtons)
    private var filterDrawerButtonSelection

    @EnvironmentObject
    private var router: SearchCoordinator.Router

    @ObservedObject
    var viewModel: SearchViewModel

    @State
    private var searchText = ""

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.suggestions, id: \.id) { item in
                Button {
                    searchText = item.displayTitle
                } label: {
                    Text(item.displayTitle)
                        .font(.body)
                }
            }
        }
    }

    @ViewBuilder
    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if !viewModel.movies.isEmpty {
                    itemsSection(title: L10n.movies, keyPath: \.movies, posterType: searchPosterType)
                }

                if !viewModel.collections.isEmpty {
                    itemsSection(title: L10n.collections, keyPath: \.collections, posterType: searchPosterType)
                }

                if !viewModel.series.isEmpty {
                    itemsSection(title: L10n.tvShows, keyPath: \.series, posterType: searchPosterType)
                }

                if !viewModel.episodes.isEmpty {
                    itemsSection(title: L10n.episodes, keyPath: \.episodes, posterType: searchPosterType)
                }

                if !viewModel.people.isEmpty {
                    itemsSection(title: L10n.people, keyPath: \.people, posterType: .portrait)
                }
            }
        }
    }

    private func baseItemOnSelect(_ item: BaseItemDto) {
        if item.type == .person {
            router.route(to: \.library, .init(parent: item, type: .person, filters: .init()))
        } else {
            router.route(to: \.item, item)
        }
    }

    @ViewBuilder
    private func itemsSection(
        title: String,
        keyPath: ReferenceWritableKeyPath<SearchViewModel, [BaseItemDto]>,
        posterType: PosterType
    ) -> some View {
        PosterHStack(
            title: title,
            type: posterType,
            items: viewModel[keyPath: keyPath].map { .item($0) }
        )
        .onSelect { item in
            baseItemOnSelect(item)
        }
    }

    var body: some View {
        Group {
            if searchText.isEmpty {
                suggestionsView
            } else if !viewModel.isLoading && viewModel.noResults {
                L10n.noResults.text
            } else {
                resultsView
            }
        }
        .onChange(of: searchText) { newText in
            viewModel.search(with: newText)
        }
        .navigationTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
        .if(!filterDrawerButtonSelection.isEmpty) { view in
            view.navBarDrawer {
                ScrollView(.horizontal, showsIndicators: false) {
                    FilterDrawerHStack(viewModel: viewModel.filterViewModel, filterDrawerButtonSelection: filterDrawerButtonSelection)
                        .onSelect { filterCoordinatorParameters in
                            router.route(to: \.filter, filterCoordinatorParameters)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 1)
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.search)
    }
}
