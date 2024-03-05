//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import UIKit

// TODO: have just `grid/list`, use separate setting for poster type
enum LibraryViewType: String, CaseIterable, Displayable, Defaults.Serializable {

    case landscapeGrid
    case portraitGrid
    case list // TODO: rename `PortraitList`

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .landscapeGrid:
            "Landscape"
        case .portraitGrid:
            "Portrait"
        case .list:
            "List"
        }
    }
}
