//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum FilterDrawerButton: String, CaseIterable, Defaults.Serializable, Displayable, Identifiable {

    case filters
    case genres
    case order
    case sort

    var displayTitle: String {
        switch self {
        case .filters:
            return L10n.filters
        case .genres:
            return L10n.genres
        case .order:
            return L10n.order
        case .sort:
            return L10n.sort
        }
    }
    
    var id: String {
        rawValue
    }

    var settingsFilter: WritableKeyPath<ItemFilters, [ItemFilters.Filter]> {
        switch self {
        case .filters:
            return \.filters
        case .genres:
            return \.genres
        case .order:
            return \.sortOrder
        case .sort:
            return \.sortBy
        }
    }
    
    var settingsSelectorType: SelectorType {
        switch self {
        case .filters, .genres:
            return .multi
        case .order, .sort:
            return .single
        }
    }
    
    var settingsItemsFilterProperty: String {
        switch self {
        case .filters:
             return "filters"
        case .genres:
            return "genres"
        case .order:
            return "sortOrder"
        case .sort:
            return "sortBy"
        }
    }
    
    func isItemsFilterActive(viewModel: FilterViewModel) -> Bool {
        switch self {
        case .filters:
            return viewModel.currentFilters.filters != []
        case .genres:
            return viewModel.currentFilters.genres != []
        case .order:
            return viewModel.currentFilters.sortOrder != [APISortOrder.ascending.filter]
        case .sort:
            return viewModel.currentFilters.sortBy != [SortBy.name.filter]
        }
    }
    
    static var defaultLibraryFilterDrawerButtons: [FilterDrawerButton] {
        [
            .filters,
            .genres,
            .order,
            .sort,
        ]
    }
    
    static var defaultSearchFilterDrawerButtons: [FilterDrawerButton] {
        [
            .filters,
            .genres,
            .order,
            .sort,
        ]
    }
}
