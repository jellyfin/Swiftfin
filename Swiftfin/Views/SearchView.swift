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
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.search(query: searchQuery)
            }
    }

    @ViewBuilder
    private var resultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                ContentGroupContentView(
                    viewModel: viewModel.itemContentGroupViewModel
                )
            }
            .edgePadding(.vertical)
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

    var body: some View {
        ZStack {
            switch viewModel.state {
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
            case .error:
                viewModel.error.map { errorView(with: $0) }
            case .searching:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationTitle(L10n.search)
        .navigationBarTitleDisplayMode(.inline)
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
