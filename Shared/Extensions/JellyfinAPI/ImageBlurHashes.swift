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
            return primary
        case .art:
            return art
        case .backdrop:
            return backdrop
        case .banner:
            return banner
        case .logo:
            return logo
        case .thumb:
            return thumb
        case .disc:
            return disc
        case .box:
            return box
        case .screenshot:
            return screenshot
        case .menu:
            return menu
        case .chapter:
            return chapter
        case .boxRear:
            return boxRear
        case .profile:
            return profile
        }
    }
}
