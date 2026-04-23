//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum UnplayedIndicatorType: String, CaseIterable, Displayable, Identifiable, Defaults.Serializable {

    case none
    case indicator
    case count

    var id: String {
        rawValue
    }

    var displayTitle: String {
        switch self {
        case .none:
            L10n.none
        case .indicator:
            L10n.indicator
        case .count:
            L10n.count
        }
    }
}
