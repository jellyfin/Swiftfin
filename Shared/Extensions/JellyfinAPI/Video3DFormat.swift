//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension Video3DFormat {
    var displayTitle: String {
        switch self {
        case .halfSideBySide:
            return L10n.halfSideBySide
        case .fullSideBySide:
            return L10n.fullSideBySide
        case .fullTopAndBottom:
            return L10n.fullTopAndBottom
        case .halfTopAndBottom:
            return L10n.halfTopAndBottom
        case .mvc:
            return L10n.mvc
        }
    }
}
