//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum ContentGroupSource: Codable, Hashable, Displayable, SystemImageable {

    case library(LibraryGroupConfiguration)
    case resume(ResumeGroupConfiguration)
    case nextUp(NextUpGroupConfiguration)
    case liveTV(LiveTVGroupConfiguration)
    case genres(GenresGroupConfiguration)

    var displayTitle: String {
        switch self {
        case let .library(configuration):
            configuration.library?.displayTitle ?? L10n.libraries
        case .resume:
            L10n.continue
        case .nextUp:
            L10n.nextUp
        case let .liveTV(configuration):
            configuration.element.displayTitle
        case .genres:
            L10n.genres
        }
    }

    var systemImage: String {
        switch self {
        case let .library(configuration):
            configuration.library?.systemImage ?? "rectangle.stack.fill"
        case .resume:
            "play.circle"
        case .nextUp:
            "text.badge.plus"
        case let .liveTV(configuration):
            configuration.element.systemImage
        case .genres:
            "theatermasks.fill"
        }
    }
}
