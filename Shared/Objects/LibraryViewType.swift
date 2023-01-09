//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum LibraryViewType: String, CaseIterable, Displayable, Defaults.Serializable {

    case grid
    case list

    // TODO: localize after organization
    var displayTitle: String {
        switch self {
        case .grid:
            return "Grid"
        case .list:
            return "List"
        }
    }
}
