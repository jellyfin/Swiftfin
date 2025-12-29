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
    private func makeGroupBody<G: _ContentGroup>(_ group: G) -> some View {
        group.body(with: group.viewModel)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(viewModel.itemContentGroupViewModel.groups, id: \.id) { group in
                    makeGroupBody(group)
                        .eraseToAnyView()
                }
            }
            .edgePadding(.vertical)
        }
        .scrollIndicators(.hidden)
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .initial:
                if viewModel.isEmpty {
                    if viewModel.canSearch {
                        Text(L10n.noResults)
                    } else {
                        suggestionsView
                    }
                } else {
                    resultsView
                }
            case .error:
                viewModel.error.map(ErrorView.init)
            case .searching:
                ProgressView()
            }
        }
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
        .backport
        .onChange(of: searchQuery) { _, newValue in
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
