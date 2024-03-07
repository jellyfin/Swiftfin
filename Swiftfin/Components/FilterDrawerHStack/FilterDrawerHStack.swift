//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct FilterDrawerHStack: View {

    @ObservedObject
    private var viewModel: FilterViewModel

    private var filterTypes: [ItemFilterType]
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

            ForEach(filterTypes, id: \.self) { type in
                FilterDrawerButton(
                    title: type.displayTitle,
                    activated: viewModel.currentFilters[keyPath: type.collectionAnyKeyPath] != ItemFilterCollection
                        .default[keyPath: type.collectionAnyKeyPath]
                )
                .onSelect {
                    onSelect(.init(type: type, viewModel: viewModel))
                }
            }
        }
    }
}

extension FilterDrawerHStack {

    init(viewModel: FilterViewModel, types: [ItemFilterType]) {
        self.init(
            viewModel: viewModel,
            filterTypes: types,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
