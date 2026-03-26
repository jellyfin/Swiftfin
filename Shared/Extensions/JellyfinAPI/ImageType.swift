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
            "The main cover image or poster for this item. This is the most prominent image shown across the app, including in libraries, search results, and detail pages."
        case .backdrop:
            "A wide background image displayed behind the item details on its media page. Multiple backdrops can be added and will cycle or be selected randomly."
        case .banner:
            "A wide horizontal image displayed when browsing the library in banner mode. Only applicable to video content."
        case .logo:
            "A transparent logo or title treatment overlaid on top of backdrops and other imagery. Used as a stylized alternative to plain text titles."
        case .thumb:
            "A thumbnail image used on the homepage and when browsing the library in thumbnail mode. Only applicable to video content."
        case .art:
            "Clear art or logo-style decorative artwork, often with a transparent background. Typically sourced from fanart providers."
        case .disc:
            "Square disc art representing physical media like CDs, DVDs, or Blu-rays. Commonly used for music albums and movie collections."
        case .box:
            "Front box art representing the physical packaging of the item, similar to what you would see on a store shelf."
        case .screenshot:
            "A screenshot or still frame captured directly from the item's video content. Deprecated and no longer actively used."
        case .menu:
            "A menu image originally intended for DVD or Blu-ray style menu navigation screens."
        case .chapter:
            "An image associated with a specific chapter marker within the item's timeline."
        case .boxRear:
            "Rear box art representing the back of the item's physical packaging, often showing descriptions or track listings."
        case .profile:
            "A profile or headshot image, typically used for people such as actors, directors, or artists."
        }
    }

    var isUsed: Bool {
        switch self {
        case .primary, .thumb, .backdrop, .banner, .logo:
            true
        default:
            false
        }
    }

    func posterDisplayType(for type: BaseItemKind? = nil) -> PosterDisplayType {
        switch self {
        case .primary:
            switch type {
            case .audio, .channel, .musicAlbum, .tvChannel:
                .square
            case .episode, .folder, .program, .musicVideo, .video, .userView:
                .landscape
            default:
                .portrait
            }
        case .disc:
            .square
        default:
            .landscape
        }
    }
}
