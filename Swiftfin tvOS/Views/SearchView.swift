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

struct SearchView: View {

    @Default(.Customization.searchPosterType)
    private var searchPosterType

    @EnvironmentObject
    private var videoPlayerRouter: VideoPlayerWrapperCoordinator.Router
    @EnvironmentObject
    private var router: SearchCoordinator.Router

    @StateObject
    private var viewModel = SearchViewModel()

    @State
    private var searchQuery = ""

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
        }
    }

    private func select(_ item: BaseItemDto) {
        switch item.type {
        case .person:
            let viewModel = ItemLibraryViewModel(parent: item)
            router.route(to: \.library, viewModel)
        case .program:
            videoPlayerRouter.route(
                to: \.liveVideoPlayer,
                LiveVideoPlayerManager(program: item)
            )
        case .tvChannel:
            guard let mediaSource = item.mediaSources?.first else { return }
            videoPlayerRouter.route(
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
        .onSelect(select)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                suggestionsView
            case .content:
                if viewModel.hasNoResults {
                    L10n.noResults.text
                } else {
                    resultsView
                }
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.search(query: searchQuery))
                    }
            case .searching:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea(edges: [.bottom, .horizontal])
        .onFirstAppear {
            viewModel.send(.getSuggestions)
        }
        .onChange(of: searchQuery) { _, newValue in
            viewModel.send(.search(query: newValue))
        }
        .searchable(text: $searchQuery, prompt: L10n.search)
    }
}
