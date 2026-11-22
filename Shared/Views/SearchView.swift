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

    @AdaptiveLayout
    private var viewLayout

    @Default(.Customization.Search.enabledDrawerFilters)
    private var enabledDrawerFilters

    @FocusState
    private var isSearchFocused: Bool

    #if os(tvOS)
    @FocusState
    private var focusedFilter: FilterTrack.FocusTarget?
    #endif

    @State
    private var viewModel = SearchViewModel()

    @StateObject
    private var focusCoordinator: FocusCoordinator = .init()

    @TabItemSelected
    private var tabItemSelected

    @ContentBuilder
    private var suggestionsView: some View {
        VStack(spacing: 20) {
            ForEach(viewModel.suggestions) { item in
                Button(item.displayTitle) {
                    viewModel.query = item.displayTitle
                }
                #if os(tvOS)
                .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                #endif
            }
        }
        .multilineTextAlignment(.center)
    }

    @ContentBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 0) {
                #if os(tvOS)
                if enabledDrawerFilters.isNotEmpty {
                    let availableTypes = viewModel.filterViewModel.availableFilterTypes(from: enabledDrawerFilters)

                    ScrollView(.horizontal) {
                        HStack(spacing: 20) {
                            FilterTrack(focus: $focusedFilter, types: availableTypes, viewModel: viewModel.filterViewModel)
                        }
                    }
                    .scrollClipDisabled()
                    .scrollIndicators(.hidden)
                    .frame(height: FilterTrack.metrics(for: viewLayout).minimumHeight)
                    .coordinatedFocusScope(
                        $focusedFilter,
                        values: availableTypes.map(FilterTrack.FocusTarget.filter)
                            .appending(.options, if: viewModel.filterViewModel.hasFilterOptions)
                    )
                    .edgePadding(.horizontal)
                    .padding(.vertical, viewLayout.itemSpacing)
                }
                #endif

                Group {
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
                }
                .frame(maxWidth: .infinity)
                .focusSection()
            }
        }
        .ignoresSafeArea(edges: viewLayout.scrollContentEdges(extendsTop: false))
        .defaultScrollAnchor(viewLayout.isLarge || viewModel.canSearch ? .top : .center, for: .alignment)
        .scrollIndicators(.hidden)
    }

    @ContentBuilder
    var body: some View {
        ZStack {
            switch viewModel.state {
            case .error:
                viewModel.error.map(ErrorView.init)

            case .initial:
                contentView

            case .searching:
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.linear(duration: 0.2), value: viewModel.state)
        .ignoresSafeArea(.keyboard)
        .navigationTitle(L10n.search)
        .toolbarTitleDisplayMode(.inline)
        .onReceive(tabItemSelected) { event in
            if event.isRepeat, event.isRoot {
                isSearchFocused = true
            }
        }
        .onFirstAppear {
            viewModel.getSuggestions()
        }
        .searchable(
            text: $viewModel.query,
            prompt: L10n.search
        )
        .searchFocused($isSearchFocused)
        .environmentObject(focusCoordinator)
        #if os(tvOS)
        .modifier(SearchSafeAreaModifier())
        #endif
        #if os(iOS)
        .navigationBarFilterDrawer(
            viewModel: viewModel.filterViewModel,
            types: enabledDrawerFilters
        )
        #endif
    }
}
