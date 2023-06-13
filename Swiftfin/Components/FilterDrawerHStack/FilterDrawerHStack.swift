//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct FilterDrawerHStack: View {

    @ObservedObject
    private var viewModel: FilterViewModel

    private var onSelect: (FilterCoordinator.Parameters) -> Void

    var body: some View {
        HStack {
            if viewModel.currentFilters.hasFilters {
                Menu {
                    Button(role: .destructive) {
                        viewModel.currentFilters = .init()
                    } label: {
                        L10n.reset.text
                    }
                } label: {
                    FilterDrawerButton(systemName: "line.3.horizontal.decrease.circle.fill", activated: true)
                }
            }

            FilterDrawerButton(title: L10n.genres, activated: viewModel.currentFilters.genres != [])
                .onSelect {
                    onSelect(.init(
                        title: L10n.genres,
                        viewModel: viewModel,
                        filter: \.genres,
                        selectorType: .multi
                    ))
                }

            FilterDrawerButton(title: L10n.filters, activated: viewModel.currentFilters.filters != [])
                .onSelect {
                    onSelect(.init(
                        title: L10n.filters,
                        viewModel: viewModel,
                        filter: \.filters,
                        selectorType: .multi
                    ))
                }

            FilterDrawerButton(title: L10n.order, activated: viewModel.currentFilters.sortOrder != [APISortOrder.ascending.filter])
                .onSelect {
                    onSelect(.init(
                        title: L10n.order,
                        viewModel: viewModel,
                        filter: \.sortOrder,
                        selectorType: .single
                    ))
                }

            FilterDrawerButton(title: L10n.sort, activated: viewModel.currentFilters.sortBy != [SortBy.name.filter])
                .onSelect {
                    onSelect(.init(
                        title: L10n.sort,
                        viewModel: viewModel,
                        filter: \.sortBy,
                        selectorType: .single
                    ))
                }
        }
    }
}

extension FilterDrawerHStack {

    init(viewModel: FilterViewModel) {
        self.init(
            viewModel: viewModel,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
