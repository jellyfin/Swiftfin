//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddServerUserAccessTagsView {

    struct SearchResultsSection: View {

        // MARK: - Element Variables

        @Binding
        var tag: String

        // MARK: - Element Search Variables

        let population: [String]
        let isSearching: Bool

        // MARK: - Body

        var body: some View {
            if tag.isNotEmpty {
                Section {
                    if population.isNotEmpty {
                        resultsView
                            .animation(.easeInOut, value: population.count)
                    } else if !isSearching {
                        noResultsView
                            .transition(.opacity)
                            .animation(.easeInOut, value: population.count)
                    }
                } header: {
                    HStack {
                        Text(L10n.existingItems)
                        if isSearching {
                            DelayedProgressView()
                        } else {
                            Text("-")
                            Text(population.count.description)
                        }
                    }
                    .animation(.easeInOut, value: isSearching)
                }
            }
        }

        // MARK: - No Results View

        private var noResultsView: some View {
            Text(L10n.none)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }

        // MARK: - Results View

        private var resultsView: some View {
            ForEach(population, id: \.self) { result in
                Button {
                    tag = result
                } label: {
                    Text(result)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundStyle(.primary)
                .disabled(tag == result)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: population.count)
            }
        }
    }
}
