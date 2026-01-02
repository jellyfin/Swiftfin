//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct SearchView: View {

    @Default(.Customization.searchPosterType)
    private var searchPosterType

    @Router
    private var router

    @State
    private var searchQuery = ""

    @StateObject
    private var viewModel = SearchViewModel()

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.suggestions) { item in
                Button(item.displayTitle) {
                    searchQuery = item.displayTitle
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
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

    private func select(_ item: BaseItemDto) {
        switch item.type {
        case .program, .tvChannel:
            let provider = item.getPlaybackItemProvider(userSession: viewModel.userSession)
            router.route(to: .videoPlayer(provider: provider))
        default:
            router.route(to: .item(item: item))
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
                    if viewModel.canSearch {
                        Text(L10n.noResults)
                    } else {
                        suggestionsView
                    }
                } else {
                    resultsView
                }
            case .searching:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea(edges: [.bottom, .horizontal])
        .refreshable {
            viewModel.search(query: searchQuery)
        }
        .onFirstAppear {
            viewModel.getSuggestions()
        }
        .onChange(of: searchQuery) { _, newValue in
            viewModel.search(query: newValue)
        }
        .searchable(text: $searchQuery, prompt: L10n.search)
    }
}
