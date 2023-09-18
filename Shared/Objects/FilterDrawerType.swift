//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//
import Defaults
import Foundation

enum FilterDrawerType: String, CaseIterable, Defaults.Serializable, Displayable, Identifiable {
    
    case library
    case search

    var displayTitle: String {
        switch self {
        case .library:
            return L10n.library
        case .search:
            return L10n.search
        }
    }
    
    var id: String {
        rawValue
    }
    
    var settingsDefaults: [FilterDrawerButton] {
        
        @Default(.Customization.Filters.libraryFilterDrawerButtons)
        var libraryFilterDrawerButtons
        
        @Default(.Customization.Filters.searchFilterDrawerButtons)
        var searchFilterDrawerButtons
        
        switch self {
        case .library:
            return libraryFilterDrawerButtons
        case .search:
            return searchFilterDrawerButtons
        }
    }
    
}
