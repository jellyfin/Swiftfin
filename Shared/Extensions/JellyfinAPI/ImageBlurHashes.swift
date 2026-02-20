//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension BaseItemDto.ImageBlurHashes {

    subscript(imageType: ImageType) -> [String: String]? {
        switch imageType {
        case .primary:
            primary
        case .art:
            art
        case .backdrop:
            backdrop
        case .banner:
            banner
        case .logo:
            logo
        case .thumb:
            thumb
        case .disc:
            disc
        case .box:
            box
        case .screenshot:
            screenshot
        case .menu:
            menu
        case .chapter:
            chapter
        case .boxRear:
            boxRear
        case .profile:
            profile
        }
    }
}
