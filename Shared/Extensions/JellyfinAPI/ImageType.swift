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
            L10n.primaryImageDescription
        case .backdrop:
            L10n.backdropImageDescription
        case .banner:
            L10n.bannerImageDescription
        case .logo:
            L10n.logoImageDescription
        case .thumb:
            L10n.thumbImageDescription
        case .art:
            L10n.artImageDescription
        case .disc:
            L10n.discImageDescription
        case .box:
            L10n.boxImageDescription
        case .screenshot:
            L10n.screenshotImageDescription
        case .menu:
            L10n.menuImageDescription
        case .chapter:
            L10n.chapterImageDescription
        case .boxRear:
            L10n.boxRearImageDescription
        case .profile:
            L10n.profileImageDescription
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
