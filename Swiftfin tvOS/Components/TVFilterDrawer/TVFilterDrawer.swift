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

struct TVFilterDrawer: View {

    struct Parameters {
        let type: ItemFilterType
        let viewModel: FilterViewModel
    }

    @ObservedObject
    private var viewModel: FilterViewModel

    private var filterTypes: [ItemFilterType]
    private var onSelect: (Parameters) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Filter buttons row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    if viewModel.currentFilters.hasFilters {
                        TVFilterButton(
                            systemName: "line.3.horizontal.decrease.circle.fill",
                            title: L10n.reset
                        )
                        .onSelect {
                            viewModel.send(.reset())
                        }
                        .isSelected(true)
                    }

                    ForEach(filterTypes, id: \.self) { type in
                        TVFilterButton(title: type.displayTitle)
                            .onSelect {
                                onSelect(.init(type: type, viewModel: viewModel))
                            }
                            .environment(
                                \.isSelected,
                                viewModel.isFilterSelected(type: type)
                            )
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
        }
        .background(.ultraThinMaterial)
    }
}

extension TVFilterDrawer {

    init(viewModel: FilterViewModel, types: [ItemFilterType]) {
        self.init(
            viewModel: viewModel,
            filterTypes: types,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
