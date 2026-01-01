//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// TODO: move to SDK

enum SeriesStatus: String, CaseIterable {

    case continuing = "Continuing"
    case ended = "Ended"
    case unreleased = "Unreleased"

    var displayTitle: String {
        switch self {
        case .continuing:
            return L10n.continuing
        case .ended:
            return L10n.ended
        case .unreleased:
            return L10n.unreleased
        }
    }
}
