//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import Defaults
import SwiftUI

struct FilterDrawerHStack: View {
    
    @ObservedObject
    private var viewModel: FilterViewModel
    
    private var filterDrawerType: FilterDrawerType

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
            ForEach(filterDrawerType.settingsDefaults, id: \.self) { button in
                FilterDrawerButton(title: button.displayTitle, activated: button.isItemsFilterActive(viewModel: viewModel))
                    .onSelect {
                        onSelect(.init(
                            title: button.displayTitle,
                            viewModel: viewModel,
                            filter: button.settingsFilter,
                            selectorType: button.settingsSelectorType
                        ))
                    }
            }
        }
    }
}

extension FilterDrawerHStack {

    init(viewModel: FilterViewModel, filterDrawerType: FilterDrawerType) {
        self.init(
            viewModel: viewModel,
            filterDrawerType: filterDrawerType,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}
