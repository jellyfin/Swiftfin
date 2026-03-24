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

    var description: String {
        switch self {
        case .primary:
            "The primary cover or artist image for this item."
        case .backdrop:
            "Background image displayed on the media page."
        case .banner:
            "Displayed when browsing the library in banner mode. Video only."
        case .logo:
            "Logo displayed on top of a media item."
        case .thumb:
            "Thumbnail for the homepage and for browsing the library in thumb mode. Video only."
        case .art:
            "Clear art or logo-style artwork used as a decorative element. Unused by official clients."
        case .disc:
            "Disc art for the item, typically a square image. Unused by official clients."
        case .box:
            "Front box art for the item. Unused by official clients."
        case .screenshot:
            "A screenshot captured from the item's content. Deprecated and unused."
        case .menu:
            "A menu image used for navigation. Unused by official clients."
        case .chapter:
            "An image associated with a chapter marker. Unused by official clients."
        case .boxRear:
            "Rear box art for the item. Unused by official clients."
        case .profile:
            "A profile image, typically used for people. Unused by official clients."
        }
    }

    func posterDisplayType(for item: BaseItemDto? = nil) -> PosterDisplayType {
        switch self {
        case .primary:
            item?.preferredPosterDisplayType ?? .portrait
        case .disc:
            .square
        default:
            .landscape
        }
    }
}
