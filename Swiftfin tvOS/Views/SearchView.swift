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

    @Router
    private var router

    @State
    private var searchQuery = ""

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
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
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
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea(edges: [.bottom, .horizontal])
        .onFirstAppear {
            viewModel.getSuggestions()
        }
        .onChange(of: searchQuery) { _, newValue in
            viewModel.search(query: newValue)
        }
        .searchable(text: $searchQuery, prompt: L10n.search)
    }
}
