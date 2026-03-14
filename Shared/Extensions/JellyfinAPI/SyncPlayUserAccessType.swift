//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension SyncPlayUserAccessType: Displayable {

    var displayTitle: String {
        switch self {
        case .createAndJoinGroups:
            L10n.createAndJoinGroups
        case .joinGroups:
            L10n.joinGroups
        case .none:
            L10n.none
        }
    }
}
