//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension SubtitlePlaybackMode: Displayable {

    var displayTitle: String {
        switch self {
        case .default:
            L10n.default
        case .always:
            L10n.always
        case .onlyForced:
            L10n.onlyForced
        case .none:
            L10n.none
        case .smart:
            L10n.smart
        }
    }

    var description: String {
        switch self {
        case .default:
            L10n.subtitleModeDefaultDescription
        case .always:
            L10n.subtitleModeAlwaysDescription
        case .onlyForced:
            L10n.subtitleModeOnlyForcedDescription
        case .none:
            L10n.subtitleModeNoneDescription
        case .smart:
            L10n.subtitleModeSmartDescription
        }
    }
}
