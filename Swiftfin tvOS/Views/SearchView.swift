//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct SearchView: View {

    @EnvironmentObject
    private var router: SearchCoordinator.Router

    @StateObject
    private var viewModel = SearchViewModel()

    @State
    private var searchQuery = ""

    @ViewBuilder
    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if viewModel.movies.isNotEmpty {
                    itemsSection(title: L10n.movies, keyPath: \.movies)
                }

                if viewModel.collections.isNotEmpty {
                    itemsSection(title: L10n.collections, keyPath: \.collections)
                }

                if viewModel.series.isNotEmpty {
                    itemsSection(title: L10n.tvShows, keyPath: \.series)
                }

                if viewModel.episodes.isNotEmpty {
                    itemsSection(title: L10n.episodes, keyPath: \.episodes)
                }

                if viewModel.people.isNotEmpty {
                    itemsSection(title: L10n.people, keyPath: \.people)
                }
            }
        }
        .ignoresSafeArea()
    }

    private func baseItemOnSelect(_ item: BaseItemDto) {
//        if item.type == .person {
//            router.route(to: \.library, .init(parent: item, type: .person, filters: .init()))
//        } else {
//            router.route(to: \.item, item)
//        }
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
            switch viewModel.state {
            case let .error(error):
                Text(error.localizedDescription)
            case .initial:
                Text("Fix me")
            case .items:
                if viewModel.hasNoResults {
                    L10n.noResults.text
                } else {
                    resultsView
                }
            case .searching:
                ProgressView()
            }
        }
        .onChange(of: searchQuery) { newValue in
            viewModel.send(.search(query: newValue))
        }
        .searchable(text: $searchQuery, prompt: L10n.search)
    }
}
