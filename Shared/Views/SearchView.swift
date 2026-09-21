//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct SearchView: View {

    @Default(.Customization.Search.enabledDrawerFilters)
    private var enabledDrawerFilters

    @FocusState
    private var isSearchFocused: Bool

    @State
    private var searchQuery = ""

    @StateObject
    private var focusCoordinator: FocusCoordinator = .init()
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
                    .foregroundStyle(.secondary)
                #endif
            }
        }
    }

    var body: some View {
        ScrollView {
            #if os(tvOS)
            FilterBar(
                viewModel: viewModel.filterViewModel,
                types: enabledDrawerFilters,
                orientation: .horizontal
            )
            .edgePadding(.horizontal)
            .padding(.vertical)
            #endif

            ZStack {
                switch viewModel.state {
                case .error:
                    viewModel.error.map(ErrorView.init)
                case .initial:
                    if viewModel.canSearch {
                        if viewModel.isEmpty {
                            Text(L10n.noResults)
                        } else {
                            ContentGroupVStack(
                                groups: viewModel.itemContentGroupViewModel.groups
                            )
                        }
                    } else {
                        suggestionsView
                    }
                case .searching:
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .focusSection()
        }
        .ignoresSafeArea(edges: .horizontal)
        .scrollIndicators(.hidden)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .ignoresSafeArea(.keyboard)
        .navigationTitle(L10n.search)
        .toolbarTitleDisplayMode(.inline)
        .searchFocused($isSearchFocused)
        .onReceive(tabItemSelected) { event in
            if event.isRepeat, event.isRoot {
                isSearchFocused = true
            }
        }
        .onFirstAppear {
            viewModel.getSuggestions()
        }
        .onChange(of: searchQuery) {
            viewModel.search(query: searchQuery)
        }
        .searchable(
            text: $searchQuery,
            prompt: L10n.search
        )
        .environmentObject(focusCoordinator)
        #if os(iOS)
        .navigationBarFilterDrawer(
            viewModel: viewModel.filterViewModel,
            types: enabledDrawerFilters
        )
        #endif
    }
}
