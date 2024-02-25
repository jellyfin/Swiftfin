//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum FilterDrawerButtonSelection: String, CaseIterable, Defaults.Serializable, Displayable, Identifiable {

    case alphaPicker
    case filters
    case genres
    case order
    case sort

    var displayTitle: String {
        switch self {
        case .alphaPicker:
            return L10n.letter
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

    var itemFilter: WritableKeyPath<ItemFilters, [ItemFilters.Filter]> {
        switch self {
        case .alphaPicker:
            return \.alphaPicker
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

    var selectorType: SelectorType {
        switch self {
        case .filters, .genres:
            return .multi
        case .alphaPicker, .order, .sort:
            return .single
        }
    }

    var itemFilterDefault: [ItemFilters.Filter] {
        switch self {
        case .alphaPicker:
            return []
        case .filters:
            return []
        case .genres:
            return []
        case .order:
            return [APISortOrder.ascending.filter]
        case .sort:
            return [SortBy.name.filter]
        }
    }

    func isItemsFilterActive(activeFilters: ItemFilters) -> Bool {
        switch self {
        case .alphaPicker:
            return activeFilters.alphaPicker != self.itemFilterDefault
        case .filters:
            return activeFilters.filters != self.itemFilterDefault
        case .genres:
            return activeFilters.genres != self.itemFilterDefault
        case .order:
            return activeFilters.sortOrder != self.itemFilterDefault
        case .sort:
            return activeFilters.sortBy != self.itemFilterDefault
        }
    }

    static var defaultLibraryFilterDrawerButtons: [FilterDrawerButtonSelection] {
        [
            .filters,
            .genres,
            .order,
            .sort,
        ]
    }

    static var defaultSearchFilterDrawerButtons: [FilterDrawerButtonSelection] {
        [
            .filters,
            .genres,
            .alphaPicker,
        ]
    }
}
