//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum UnplayedIndicatorType: String, CaseIterable, Displayable, Identifiable, _DefaultsSerializable {

    case hidden
    case icon
    case count

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .hidden:
            return "None"
        case .icon:
            return "Triangle"
        case .count:
            return "Count"
        }
    }
}
