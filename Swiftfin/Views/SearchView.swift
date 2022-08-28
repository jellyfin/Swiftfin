//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct SearchView: View {

    @EnvironmentObject
    private var router: SearchCoordinator.Router
    @ObservedObject
    var viewModel: SearchViewModel

    @Default(.Customization.searchPosterType)
    private var searchPosterType
    @State
    private var searchText = ""

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.suggestions, id: \.id) { item in
                Button {
                    searchText = item.displayName
                } label: {
                    Text(item.displayName)
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
                    // TODO: Localize after organization
                    itemsSection(title: "Collections", keyPath: \.collections, posterType: searchPosterType)
                }

                if !viewModel.series.isEmpty {
                    itemsSection(title: L10n.tvShows, keyPath: \.series, posterType: searchPosterType)
                }

                if !viewModel.episodes.isEmpty {
                    itemsSection(title: L10n.episodes, keyPath: \.episodes, posterType: searchPosterType)
                }

                if !viewModel.people.isEmpty {
                    // TODO: Localize after organization
                    itemsSection(title: "People", keyPath: \.people, posterType: .portrait)
                }
            }
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
            items: viewModel[keyPath: keyPath]
        )
        .onSelect { item in
            router.route(to: \.item, item)
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
        .searchable(text: $searchText, placement: .navigationBarDrawer, prompt: L10n.search)
        .navigationTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
    }
}
