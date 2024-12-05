//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension AddItemComponentView {

    struct MatchesSection: View {

        @Binding
        var id: String?
        @Binding
        var name: String

        let type: ItemArrayElements
        let matches: [Element]
        let isSearching: Bool

        // MARK: - Body

        var body: some View {
            if name.isNotEmpty {
                Section {
                    if matches.isEmpty {
                        noMatchesView
                    } else {
                        matchesView
                    }
                } header: {
                    HStack {
                        Text(L10n.matches)
                        if isSearching {
                            DelayedProgressView()
                        }
                    }
                }
            }
        }

        // MARK: - Empty Matches Results

        private var noMatchesView: some View {
            Text(isSearching ? L10n.searchingDots : L10n.none)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }

        // MARK: - Formatted Matches Results

        private var matchesView: some View {
            ForEach(matches, id: \.self) { match in
                Button {
                    name = type.getName(for: match)
                    id = type.getId(for: match)
                } label: {
                    labelView(match)
                }
                .foregroundStyle(.primary)
                .disabled(name == type.getName(for: match))
            }
        }

        // MARK: - Element Matches Button Label by Type

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
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.primary)
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
