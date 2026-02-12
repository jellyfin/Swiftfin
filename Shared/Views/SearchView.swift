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

    @Default(.Customization.Search.enabledDrawerFilters)
    private var enabledDrawerFilters

    @FocusState
    private var isSearchFocused: Bool

    @Router
    private var router

    @State
    private var searchQuery = ""

    @StateObject
    private var viewModel = SearchViewModel()

    @TabItemSelected
    private var tabItemSelected

    @ViewBuilder
    private var suggestionsView: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.suggestions) { item in
                Button(item.displayTitle) {
                    searchQuery = item.displayTitle
                }
                #if os(tvOS)
                .buttonStyle(.plain)
                #endif
            }
        }
    }

    @ViewBuilder
    private func makeGroupBody<G: ContentGroup>(_ group: G) -> some View {
        group.body(with: group.viewModel)
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
                if viewModel.canSearch {
                    if viewModel.isEmpty {
                        Text(L10n.noResults)
                    } else {
                        resultsView
                    }
                } else {
                    suggestionsView
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
        .backport
        .toolbarTitleDisplayMode(.inline)
//        .navigationBarFilterDrawer(
//            viewModel: viewModel.filterViewModel,
//            types: enabledDrawerFilters
//        )
        .onFirstAppear {
            viewModel.getSuggestions()
        }
        .backport
        .onChange(of: searchQuery) { _, newValue in
            viewModel.search(query: newValue)
        }
        .searchable(
            text: $searchQuery,
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
