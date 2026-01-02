//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum PanGestureAction: String, GestureAction {

    case none
    case brightness
    case scrub
    case slowScrub
    case volume

    var displayTitle: String {
        switch self {
        case .none:
            return L10n.none
        case .brightness:
            return L10n.brightness
        case .scrub:
            return L10n.scrub
        case .slowScrub:
            return L10n.slowScrub
        case .volume:
            return L10n.volume
        }
    }
}
