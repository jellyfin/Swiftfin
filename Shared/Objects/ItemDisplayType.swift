//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

enum ItemDisplayType: String, CaseIterable, Displayable, Defaults.Serializable {

    /// Example: thumb posters
    case narrow

    /// Example: album art
    case square

    /// Example: portrait posters
    case wide

    // TODO: localize
    var displayTitle: String {
        switch self {
        case .narrow:
            "Portrait"
        case .square:
            "Square"
        case .wide:
            "Wide"
        }
    }
}
