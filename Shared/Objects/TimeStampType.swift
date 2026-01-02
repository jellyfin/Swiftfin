//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum TimestampType: String, CaseIterable, Defaults.Serializable, Displayable {

    case split
    case compact

    var displayTitle: String {
        switch self {
        case .split:
            return L10n.split
        case .compact:
            return L10n.compact
        }
    }
}
