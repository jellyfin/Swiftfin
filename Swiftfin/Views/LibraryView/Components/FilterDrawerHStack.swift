//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct FilterDrawerHStack: View {

    @EnvironmentObject
    private var router: LibraryCoordinator.Router

    @ObservedObject
    var viewModel: FilterViewModel

    var body: some View {
        HStack {
            if viewModel.currentFilters.hasFilters {
                Menu {
                    Button(role: .destructive) {
                        viewModel.currentFilters = .default
                    } label: {
                        L10n.reset.text
                    }
                } label: {
                    FilterDrawerButton(systemName: "line.3.horizontal.decrease.circle.fill", activated: true)
                }
            }

            FilterDrawerButton(title: "Genres", activated: viewModel.currentFilters.genres != [])
                .onSelect {
                    router.route(to: \.filter, .init(
                        title: "Genres",
                        viewModel: viewModel,
                        filter: \.genres,
                        singleSelect: false
                    ))
                }

            FilterDrawerButton(title: "Tags", activated: viewModel.currentFilters.tags != [])
                .onSelect {
                    router.route(to: \.filter, .init(
                        title: "Tags",
                        viewModel: viewModel,
                        filter: \.tags,
                        singleSelect: false
                    ))
                }

            FilterDrawerButton(title: "Filters", activated: viewModel.currentFilters.filters != [])
                .onSelect {
                    router.route(to: \.filter, .init(
                        title: "Filters",
                        viewModel: viewModel,
                        filter: \.filters,
                        singleSelect: false
                    ))
                }

            FilterDrawerButton(title: "Order", activated: viewModel.currentFilters.sortOrder != [APISortOrder.ascending.filter])
                .onSelect {
                    router.route(to: \.filter, .init(
                        title: "Order",
                        viewModel: viewModel,
                        filter: \.sortOrder,
                        singleSelect: true
                    ))
                }

            FilterDrawerButton(title: "Sort", activated: viewModel.currentFilters.sortBy != [SortBy.name.filter])
                .onSelect {
                    router.route(to: \.filter, .init(
                        title: "Sort",
                        viewModel: viewModel,
                        filter: \.sortBy,
                        singleSelect: true
                    ))
                }
        }
    }
}
