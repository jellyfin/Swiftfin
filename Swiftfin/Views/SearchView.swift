//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

// TODO: have a `SearchLibraryViewModel` that allows paging on searched items?
// TODO: implement search view result type between `PosterHStack`
//       and `ListHStack` (3 row list columns)? (iOS only)
// TODO: have programs only pull recommended/current?
//       - have progress overlay
struct SearchView: View {

    @Default(.Customization.Search.enabledDrawerFilters)
    private var enabledDrawerFilters
    @Default(.Customization.searchPosterType)
    private var searchPosterType

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router
    @EnvironmentObject
    private var router: SearchCoordinator.Router

    @State
    private var searchQuery = ""

    @StateObject
    private var viewModel = SearchViewModel()

    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.search(query: searchQuery))
            }
    }

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.suggestions) { item in
                Button(item.displayTitle) {
                    searchQuery = item.displayTitle
                }
            }
        }
    }

    @ViewBuilder
    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if viewModel.movies.isNotEmpty {
                    itemsSection(title: L10n.movies, keyPath: \.movies, posterType: searchPosterType)
                }

                if viewModel.series.isNotEmpty {
                    itemsSection(title: L10n.tvShows, keyPath: \.series, posterType: searchPosterType)
                }

                if viewModel.collections.isNotEmpty {
                    itemsSection(title: L10n.collections, keyPath: \.collections, posterType: searchPosterType)
                }

                if viewModel.episodes.isNotEmpty {
                    itemsSection(title: L10n.episodes, keyPath: \.episodes, posterType: searchPosterType)
                }

                if viewModel.programs.isNotEmpty {
                    itemsSection(title: L10n.programs, keyPath: \.programs, posterType: .landscape)
                }

                if viewModel.channels.isNotEmpty {
                    itemsSection(title: L10n.channels, keyPath: \.channels, posterType: .portrait)
                }

                if viewModel.people.isNotEmpty {
                    itemsSection(title: L10n.people, keyPath: \.people, posterType: .portrait)
                }
            }
            .edgePadding(.vertical)
        }
    }

    private func select(_ item: BaseItemDto) {
        switch item.type {
        case .person:
            let viewModel = ItemLibraryViewModel(parent: item)
            router.route(to: \.library, viewModel)
        case .program:
            mainRouter.route(
                to: \.liveVideoPlayer,
                LiveVideoPlayerManager(program: item)
            )
        case .tvChannel:
            guard let mediaSource = item.mediaSources?.first else { return }
            mainRouter.route(
                to: \.liveVideoPlayer,
                LiveVideoPlayerManager(item: item, mediaSource: mediaSource)
            )
        default:
            router.route(to: \.item, item)
        }
    }

    @ViewBuilder
    private func itemsSection(
        title: String,
        keyPath: KeyPath<SearchViewModel, [BaseItemDto]>,
        posterType: PosterDisplayType
    ) -> some View {
        PosterHStack(
            title: title,
            type: posterType,
            items: viewModel[keyPath: keyPath]
        )
        .trailing {
            SeeAllButton()
                .onSelect {
                    let viewModel = PagingLibraryViewModel(
                        title: title,
                        id: "search-\(keyPath.hashValue)",
                        viewModel[keyPath: keyPath]
                    )
                    router.route(to: \.library, viewModel)
                }
        }
        .onSelect(select)
    }

    var body: some View {
        WrappedView {
            Group {
                switch viewModel.state {
                case let .error(error):
                    errorView(with: error)
                case .initial:
                    suggestionsView
                case .content:
                    if viewModel.hasNoResults {
                        L10n.noResults.text
                    } else {
                        resultsView
                    }
                case .searching:
                    ProgressView()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarFilterDrawer(
            viewModel: viewModel.filterViewModel,
            types: enabledDrawerFilters
        ) {
            router.route(to: \.filter, $0)
        }
        .onFirstAppear {
            viewModel.send(.getSuggestions)
        }
        .onChange(of: searchQuery) { newValue in
            viewModel.send(.search(query: newValue))
        }
        .searchable(
            text: $searchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.search
        )
    }
}
