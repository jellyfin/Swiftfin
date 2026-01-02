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
            return L10n.primary
        case .art:
            return L10n.art
        case .backdrop:
            return L10n.backdrop
        case .banner:
            return L10n.banner
        case .logo:
            return L10n.logo
        case .thumb:
            return L10n.thumb
        case .disc:
            return L10n.disc
        case .box:
            return L10n.box
        case .screenshot:
            return L10n.screenshot
        case .menu:
            return L10n.menu
        case .chapter:
            return L10n.chapter
        case .boxRear:
            return L10n.boxRear
        case .profile:
            return L10n.profile
        }
    }
}
