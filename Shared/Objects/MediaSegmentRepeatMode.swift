//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum MediaSegmentRepeatMode: String, CaseIterable, Displayable, Storable {

    case once
    case everyTime

    var displayTitle: String {
        switch self {
        case .once:
            L10n.once
        case .everyTime:
            L10n.everyTime
        }
    }

    var description: String {
        switch self {
        case .once:
            L10n.mediaSegmentOnceDescription
        case .everyTime:
            L10n.mediaSegmentEveryTimeDescription
        }
    }
}
