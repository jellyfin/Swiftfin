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

struct NavigationBarFilterDrawer: View {

    @ObservedObject
    private var viewModel: FilterViewModel

    private var filterTypes: [ItemFilterType]
    private var onSelect: (FilterCoordinator.Parameters) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if viewModel.currentFilters.hasFilters {
                    Menu {
                        Button(L10n.reset, role: .destructive) {
                            viewModel.currentFilters = .default
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
            .padding(.horizontal)
            .padding(.vertical, 1)
        }
    }
}

extension NavigationBarFilterDrawer {

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
