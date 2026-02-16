//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension ImageType: Displayable {

    var displayTitle: String {
        switch self {
        case .primary:
            L10n.primary
        case .art:
            L10n.art
        case .backdrop:
            L10n.backdrop
        case .banner:
            L10n.banner
        case .logo:
            L10n.logo
        case .thumb:
            L10n.thumb
        case .disc:
            L10n.disc
        case .box:
            L10n.box
        case .screenshot:
            L10n.screenshot
        case .menu:
            L10n.menu
        case .chapter:
            L10n.chapter
        case .boxRear:
            L10n.boxRear
        case .profile:
            L10n.profile
        }
    }
}
