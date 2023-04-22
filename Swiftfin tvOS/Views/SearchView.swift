//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SearchView: View {

    @EnvironmentObject
    private var router: SearchCoordinator.Router

    @ObservedObject
    var viewModel: SearchViewModel

    @State
    private var searchText = ""

    @ViewBuilder
    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if !viewModel.movies.isEmpty {
                    itemsSection(title: L10n.movies, keyPath: \.movies)
                }

                if !viewModel.collections.isEmpty {
                    itemsSection(title: L10n.collections, keyPath: \.collections)
                }

                if !viewModel.series.isEmpty {
                    itemsSection(title: L10n.tvShows, keyPath: \.series)
                }

                if !viewModel.episodes.isEmpty {
                    itemsSection(title: L10n.episodes, keyPath: \.episodes)
                }

                if !viewModel.people.isEmpty {
                    itemsSection(title: L10n.people, keyPath: \.people)
                }
            }
        }
        .ignoresSafeArea()
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
        keyPath: ReferenceWritableKeyPath<SearchViewModel, [BaseItemDto]>
    ) -> some View {
        PosterHStack(
            title: title,
            type: .portrait,
            items: viewModel[keyPath: keyPath]
        )
        .onSelect { item in
            baseItemOnSelect(item)
        }
    }

    var body: some View {
        Group {
            if searchText.isEmpty {
                EmptyView()
            } else if !viewModel.isLoading && viewModel.noResults {
                L10n.noResults.text
            } else {
                resultsView
            }
        }
        .onChange(of: searchText) { newText in
            viewModel.search(with: newText)
        }
        .searchable(text: $searchText, prompt: L10n.search)
    }
}
