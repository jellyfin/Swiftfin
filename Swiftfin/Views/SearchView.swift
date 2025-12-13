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

    @FocusState
    private var isSearchFocused: Bool

    @Router
    private var router

    @State
    private var searchQuery = ""

    @TabItemSelected
    private var tabItemSelected

    @StateObject
    private var viewModel = SearchViewModel()

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
                if let movies = viewModel.items[.movie], movies.isNotEmpty {
                    itemsSection(
                        title: L10n.movies,
                        type: .movie,
                        items: movies,
                        posterType: searchPosterType
                    )
                }

                if let series = viewModel.items[.series], series.isNotEmpty {
                    itemsSection(
                        title: L10n.tvShows,
                        type: .series,
                        items: series,
                        posterType: searchPosterType
                    )
                }

                if let collections = viewModel.items[.boxSet], collections.isNotEmpty {
                    itemsSection(
                        title: L10n.collections,
                        type: .boxSet,
                        items: collections,
                        posterType: searchPosterType
                    )
                }

                if let episodes = viewModel.items[.episode], episodes.isNotEmpty {
                    itemsSection(
                        title: L10n.episodes,
                        type: .episode,
                        items: episodes,
                        posterType: searchPosterType
                    )
                }

                if let musicVideos = viewModel.items[.musicVideo], musicVideos.isNotEmpty {
                    itemsSection(
                        title: L10n.musicVideos,
                        type: .musicVideo,
                        items: musicVideos,
                        posterType: .landscape
                    )
                }

                if let videos = viewModel.items[.video], videos.isNotEmpty {
                    itemsSection(
                        title: L10n.videos,
                        type: .video,
                        items: videos,
                        posterType: .landscape
                    )
                }

                if let programs = viewModel.items[.program], programs.isNotEmpty {
                    itemsSection(
                        title: L10n.programs,
                        type: .program,
                        items: programs,
                        posterType: .landscape
                    )
                }

                if let channels = viewModel.items[.tvChannel], channels.isNotEmpty {
                    itemsSection(
                        title: L10n.channels,
                        type: .tvChannel,
                        items: channels,
                        posterType: .square
                    )
                }

                if let musicArtists = viewModel.items[.musicArtist], musicArtists.isNotEmpty {
                    itemsSection(
                        title: L10n.artists,
                        type: .musicArtist,
                        items: musicArtists,
                        posterType: .portrait
                    )
                }

                if let people = viewModel.items[.person], people.isNotEmpty {
                    itemsSection(
                        title: L10n.people,
                        type: .person,
                        items: people,
                        posterType: .portrait
                    )
                }
            }
            .edgePadding(.vertical)
        }
    }

    private func select(_ item: BaseItemDto, in namespace: Namespace.ID) {
        switch item.type {
        case .program, .tvChannel:
            let provider = item.getPlaybackItemProvider(userSession: viewModel.userSession)
            router.route(to: .videoPlayer(provider: provider))
        default:
            router.route(to: .item(item: item), in: namespace)
        }
    }

    @ViewBuilder
    private func itemsSection(
        title: String,
        type: BaseItemKind,
        items: [BaseItemDto],
        posterType: PosterDisplayType
    ) -> some View {
        PosterHStack(
            title: title,
            type: posterType,
            items: items,
            action: select
        )
        .trailing {
            SeeAllButton()
                .onSelect {
                    let viewModel = PagingLibraryViewModel(
                        title: title,
                        id: "search-\(type.hashValue)",
                        items
                    )
                    router.route(to: .library(viewModel: viewModel))
                }
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map {
                    ErrorView(error: $0)
                }
            case .initial:
                if viewModel.hasNoResults {
                    if searchQuery.isEmpty {
                        suggestionsView
                    } else {
                        Text(L10n.noResults)
                    }
                } else {
                    resultsView
                }
            case .searching:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.items)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.search(query: searchQuery)
        }
        .navigationBarFilterDrawer(
            viewModel: viewModel.filterViewModel,
            types: enabledDrawerFilters
        ) {
            router.route(to: .filter(type: $0.type, viewModel: $0.viewModel))
        }
        .onFirstAppear {
            viewModel.getSuggestions()
        }
        .onChange(of: searchQuery) { newValue in
            viewModel.search(query: newValue)
        }
        .searchable(
            text: $searchQuery,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: L10n.search
        )
        .backport
        .searchFocused($isSearchFocused)
        .onReceive(tabItemSelected) { event in
            if event.isRepeat, event.isRoot {
                isSearchFocused = true
            }
        }
    }
}
