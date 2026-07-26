//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum TabIcon {

    struct Choice: Hashable, Identifiable {

        let title: String
        let systemImage: String

        var id: String {
            systemImage
        }
    }

    static let choices = [
        Choice(title: L10n.home, systemImage: "house.fill"),
        Choice(title: L10n.search, systemImage: "magnifyingglass"),
        Choice(title: L10n.libraries, systemImage: "rectangle.stack.fill"),
        Choice(title: L10n.liveTV, systemImage: "play.tv.fill"),
        Choice(title: L10n.movies, systemImage: "film.fill"),
        Choice(title: L10n.tvShowsCapitalized, systemImage: "tv.fill"),
        Choice(title: L10n.folder, systemImage: "folder.fill"),
        Choice(title: L10n.favorite, systemImage: "star.fill"),
        Choice(title: L10n.likes, systemImage: "heart.fill"),
        Choice(title: L10n.recentlyAdded, systemImage: "clock.fill"),
        Choice(title: L10n.play, systemImage: "play.rectangle.on.rectangle.fill"),
        Choice(title: L10n.music, systemImage: "music.note"),
        Choice(title: L10n.profile, systemImage: "person.fill"),
        Choice(title: L10n.people, systemImage: "person.2.fill"),
        Choice(title: L10n.grid, systemImage: "square.grid.2x2.fill"),
        Choice(title: L10n.recommended, systemImage: "sparkles"),
        Choice(title: L10n.dashboard, systemImage: "server.rack"),
        Choice(title: L10n.activity, systemImage: "list.bullet.rectangle"),
    ]
}
