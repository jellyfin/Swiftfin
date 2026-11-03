//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension PluginStatus: Displayable {

    var displayTitle: String {
        switch self {
        case .active:
            L10n.active
        case .restart:
            L10n.restartRequired
        case .deleted:
            L10n.deleted
        case .superseded, .superceded:
            L10n.superseded
        case .malfunctioned:
            L10n.malfunctioned
        case .notSupported:
            L10n.notSupported
        case .disabled:
            L10n.disabled
        }
    }
}
