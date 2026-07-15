//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum LibraryDisplayType: String, SupportedCaseIterable, CaseIterable, Displayable, Storable, SystemImageable {

    case grid
    case list
    case guide

    var displayTitle: String {
        switch self {
        case .grid:
            L10n.grid
        case .list:
            L10n.list
        case .guide:
            L10n.guide
        }
    }

    var systemImage: String {
        switch self {
        case .grid:
            "square.grid.2x2.fill"
        case .list:
            "square.fill.text.grid.1x2"
        case .guide:
            "tablecells"
        }
    }

    static var supportedCases: [LibraryDisplayType] {
        [.grid, .list]
    }
}
