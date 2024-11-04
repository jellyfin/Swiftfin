//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension Video3DFormat {
    var displayTitle: String {
        switch self {
        case .halfSideBySide:
            return "Half Side-by-Side"
        case .fullSideBySide:
            return "Full Side-by-Side"
        case .fullTopAndBottom:
            return "Full Top and Bottom"
        case .halfTopAndBottom:
            return "Half Top and Bottom"
        case .mvc:
            return "MVC"
        }
    }
}
