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

struct LeadingBarFilterDrawer: View {

    @ObservedObject
    private var viewModel: FilterViewModel

    private var filterTypes: [ItemFilterType]
    private var onSelect: (FilterCoordinator.Parameters) -> Void

    var body: some View {
        VStack {
            if viewModel.currentFilters.hasFilters {
                FilterDrawerButton(
                    systemName: "line.3.horizontal.decrease.circle.fill",
                    title: L10n.reset
                )
                .onSelect {
                    viewModel.send(.reset())
                }
                .environment(\.isSelected, true)
            }

            ForEach(filterTypes, id: \.self) { type in
                FilterDrawerButton(
                    systemName: type.systemImage,
                    title: type.displayTitle
                )
                .onSelect {
                    onSelect(.init(type: type, viewModel: viewModel))
                }
                .environment(
                    \.isSelected,
                    viewModel.isFilterSelected(type: type)
                )
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 1)
    }
}

extension LeadingBarFilterDrawer {

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
