//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddItemElementView {

    struct SearchResultsSection: View {

        // MARK: - Element Variables

        @Binding
        var name: String
        @Binding
        var id: String?

        // MARK: - Element Search Variables

        let type: ItemArrayElements
        let population: [Element]

        // TODO: Why doesn't environment(\.isSearching) work?
        let isSearching: Bool

        // MARK: - Body

        var body: some View {
            if name.isNotEmpty {
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
                    name = type.getName(for: result)
                    id = type.getId(for: result)
                } label: {
                    labelView(result)
                }
                .foregroundStyle(.primary)
                .disabled(name == type.getName(for: result))
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: population.count)
            }
        }

        // MARK: - Label View

        @ViewBuilder
        private func labelView(_ match: Element) -> some View {
            switch type {
            case .people:
                let person = match as! BaseItemPerson
                HStack {
                    ZStack {
                        Color.clear
                        ImageView(person.portraitImageSources(maxWidth: 30))
                            .failure {
                                SystemImageContentView(systemName: "person.fill")
                            }
                    }
                    .posterStyle(.portrait)
                    .frame(width: 30, height: 90)
                    .padding(.horizontal)

                    Text(type.getName(for: match))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            default:
                Text(type.getName(for: match))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
