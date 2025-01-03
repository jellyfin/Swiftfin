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

        let tags: [String]
        let isSearching: Bool

        // MARK: - Body

        var body: some View {
            if tag.isNotEmpty {
                Section {
                    if tags.isNotEmpty {
                        resultsView
                    } else if !isSearching {
                        noResultsView
                    }
                } header: {
                    HStack {
                        Text(L10n.existingItems)

                        if isSearching {
                            ProgressView()
                        } else {
                            Text("-")

                            Text(tags.count, format: .number)
                        }
                    }
                }
                .animation(.linear(duration: 0.2), value: tags)
            }
        }

        // MARK: - No Results View

        private var noResultsView: some View {
            Text(L10n.none)
                .foregroundStyle(.secondary)
        }

        // MARK: - Results View

        private var resultsView: some View {
            ForEach(tags, id: \.self) { result in
                Button(result) {
                    tag = result
                }
                .foregroundStyle(.primary)
                .disabled(tag == result)
            }
        }
    }
}
