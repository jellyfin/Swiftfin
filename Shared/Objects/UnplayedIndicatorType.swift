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
    case indicator
    case count

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .hidden:
            return L10n.none
        case .indicator:
            return L10n.indicator
        case .count:
            return L10n.count
        }
    }
}
