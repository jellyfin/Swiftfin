//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct NavigationBarFilterDrawer: View {

    struct Parameters {
        let type: ItemFilterType
        let viewModel: FilterViewModel
    }

    private let action: (Parameters) -> Void
    private let filterTypes: [ItemFilterType]
    private let viewModel: FilterViewModel

    init(
        viewModel: FilterViewModel,
        types: [ItemFilterType],
        action: @escaping (Parameters) -> Void
    ) {
        self.viewModel = viewModel
        self.filterTypes = types
        self.action = action
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                if viewModel.currentFilters.hasFilters {
                    Menu(L10n.reset, systemImage: "line.3.horizontal.decrease") {
                        Button(L10n.reset, role: .destructive) {
                            viewModel.reset(filterType: nil)
                        }
                    }
                    .foregroundStyle(.primary, .secondary)
                    .isSelected(true)
                    .labelStyle(.navigationDrawer.iconOnly)
                }

                ForEach(filterTypes, id: \.self) { type in
                    Button {
                        action(.init(type: type, viewModel: viewModel))
                    } label: {
                        Label {
                            Text(type.displayTitle)
                        } icon: {
                            EmptyView()
                        }
                    }
                    .foregroundStyle(.primary, .secondary)
                    .isSelected(
                        viewModel.isFilterSelected(type: type)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 1)
            .labelStyle(.navigationDrawer)
        }
    }
}
