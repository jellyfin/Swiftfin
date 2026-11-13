//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum TabDestination: Codable, Hashable, Displayable, SystemImageable {

    case home
    case search
    case media
    case liveTV
    case contentView(id: String)
    case item(ItemReference)
    case admin(AdminTabDestination)

    static func presets(isAdministrator: Bool) -> [Self] {
        [.home, .search, .media, .liveTV] + (isAdministrator ? AdminTabDestination.allCases.map(admin) : [])
    }

    var displayTitle: String {
        switch self {
        case .home:
            L10n.home
        case .search:
            L10n.search
        case .media:
            L10n.media
        case .liveTV:
            L10n.liveTV
        case .contentView:
            L10n.userView
        case let .item(item):
            item.displayTitle
        case let .admin(destination):
            destination.displayTitle
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            "house.fill"
        case .search:
            "magnifyingglass"
        case .media:
            "rectangle.stack.fill"
        case .liveTV:
            "play.tv"
        case .contentView:
            "rectangle.stack.badge.play.fill"
        case let .item(item):
            item.systemImage
        case let .admin(destination):
            destination.systemImage
        }
    }
}
