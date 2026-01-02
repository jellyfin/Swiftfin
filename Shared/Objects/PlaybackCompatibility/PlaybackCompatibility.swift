//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

enum PlaybackCompatibility: String, CaseIterable, Defaults.Serializable, Displayable {

    case auto
    case mostCompatible
    case directPlay
    case custom

    var displayTitle: String {
        switch self {
        case .auto:
            return L10n.auto
        case .mostCompatible:
            return L10n.compatible
        case .directPlay:
            return L10n.directPlay
        case .custom:
            return L10n.custom
        }
    }
}
