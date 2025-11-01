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

struct LibraryHeader: View {

    // MARK: - Properties

    let title: String
    let totalCount: Int
    let filterViewModel: FilterViewModel

    @Router
    private var router

    // MARK: - Body

    var body: some View {
        HStack {
            // Library title
            HStack(alignment: .center, spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                // Items count
                Text("(\(totalCount) \(L10n.items.lowercased()))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 7)
            }

            Spacer()

            // Filter buttons
            HStack(spacing: 30) {

                Button(action: {
                    router.route(to: .filter(type: ItemFilterType.traits, viewModel: filterViewModel))
                }) {
                    HStack(spacing: 10) {
                        Text(filterButtonTitle)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }

                Text(L10n.by.lowercased())

                Button(action: {
                    router.route(to: .filter(type: ItemFilterType.sortBy, viewModel: filterViewModel))
                }) {
                    HStack(spacing: 10) {
                        Text(sortButtonTitle)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                }

                if filterViewModel.currentFilters.hasFilters {
                    Button(action: {
                        filterViewModel.send(.reset())
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.circle")
                            Text(L10n.reset)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 10, leading: 60, bottom: 10, trailing: 60))
        .ignoresSafeArea()
    }

    // MARK: - Computed Properties

    private var filterButtonTitle: String {
        let filters = filterViewModel.currentFilters
        var titles: [String] = []

        // Add trait filters
        if !filters.traits.isEmpty {
            let traitNames = filters.traits.map(\.displayTitle)
            titles.append(contentsOf: traitNames)
        }

        // Add genre filters
        if !filters.genres.isEmpty {
            let genreNames = filters.genres.map(\.value)
            titles.append(contentsOf: genreNames)
        }

        // Add year filters
        if !filters.years.isEmpty {
            let yearNames = filters.years.map(\.value)
            titles.append(contentsOf: yearNames)
        }

        return titles.isEmpty ? L10n.all.capitalized : titles.joined(separator: " • ")
    }

    private var sortButtonTitle: String {
        let filters = filterViewModel.currentFilters
        if let sortBy = filters.sortBy.first {
            // Handle specific cases where displayTitle might be too verbose
            switch sortBy {
            case .name:
                return L10n.name.capitalized
            default:
                return sortBy.displayTitle
            }
        }
        return L10n.name.capitalized
    }
}
