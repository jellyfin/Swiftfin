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

    @Default(.Customization.Filters.filterDrawerButtons)
    private var filterActiveDrawerButtons
    
    @ObservedObject
    private var viewModel: FilterViewModel

    private var onSelect: (FilterCoordinator.Parameters) -> Void

    var body: some View {
        HStack {
            if !filterActiveDrawerButtons.isEmpty && viewModel.currentFilters.hasFilters {
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
            ForEach(filterActiveDrawerButtons, id: \.self) { button in
                FilterDrawerButton(title: button.displayTitle, activated: getFilterProperty(
                    from: viewModel.currentFilters, propertyName: button.settingsItemsFilterProperty) != button.settingsItemsFilterInactive)
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

    init(viewModel: FilterViewModel) {
        self.init(
            viewModel: viewModel,
            onSelect: { _ in }
        )
    }

    func onSelect(_ action: @escaping (FilterCoordinator.Parameters) -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
    
    // Finds the Filters/Genres/SortBy/Etc Property from the the ItemsFilter & 
    func getFilterProperty<T>(from object: T, propertyName: String) -> [ItemFilters.Filter] {
        let mirror = Mirror(reflecting: object)
        
        for child in mirror.children {
            if let label = child.label, label == propertyName {
                if let filterProperties = child.value as? [ItemFilters.Filter] {
                    return filterProperties
                }
            }
        }
        
        return []
    }
}
