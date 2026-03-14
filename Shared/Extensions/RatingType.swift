//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension RatingType: Displayable {

    var displayTitle: String {
        switch self {
        case .score:
            L10n.score
        case .likes:
            L10n.likes
        }
    }
}
