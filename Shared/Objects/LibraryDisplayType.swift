//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum LibraryDisplayType: String, CaseIterable, Displayable, Storable, SystemImageable {

    case grid
    case list

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .grid:
            L10n.grid
        case .list:
            L10n.list
        }
    }

    var systemImage: String {
        switch self {
        case .grid:
            "square.grid.2x2.fill"
        case .list:
            "square.fill.text.grid.1x2"
        }
    }
}
