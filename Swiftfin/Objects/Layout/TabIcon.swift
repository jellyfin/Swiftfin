//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct TabIcon: Identifiable {

    let title: String
    let systemImage: String

    var id: String {
        systemImage
    }

    static let choices: [Self] = [
        .init(title: L10n.userView, systemImage: "rectangle.3.group"),
        .init(title: L10n.home, systemImage: "house.fill"),
        .init(title: L10n.search, systemImage: "magnifyingglass"),
        .init(title: L10n.libraries, systemImage: "rectangle.stack.fill"),
        .init(title: L10n.liveTV, systemImage: "play.tv.fill"),
        .init(title: L10n.movies, systemImage: "film.fill"),
        .init(title: L10n.tvShowsCapitalized, systemImage: "tv.fill"),
        .init(title: L10n.folder, systemImage: "folder.fill"),
        .init(title: L10n.favorite, systemImage: "star.fill"),
        .init(title: L10n.likes, systemImage: "heart.fill"),
        .init(title: L10n.recentlyAdded, systemImage: "clock.fill"),
        .init(title: L10n.play, systemImage: "play.rectangle.on.rectangle.fill"),
        .init(title: L10n.music, systemImage: "music.note"),
        .init(title: L10n.profile, systemImage: "person.fill"),
        .init(title: L10n.people, systemImage: "person.2.fill"),
        .init(title: L10n.grid, systemImage: "square.grid.2x2.fill"),
        .init(title: L10n.recommended, systemImage: "sparkles"),
        .init(title: L10n.dashboard, systemImage: "server.rack"),
        .init(title: L10n.activity, systemImage: "list.bullet.rectangle"),
        .init(title: L10n.collections, systemImage: "square.stack.3d.up.fill"),
        .init(title: L10n.list, systemImage: "list.bullet"),
        .init(title: L10n.playlists, systemImage: "music.note.list"),
        .init(title: L10n.photos, systemImage: "photo.fill"),
        .init(title: L10n.books, systemImage: "book.closed.fill"),
        .init(title: L10n.audio, systemImage: "headphones"),
        .init(title: L10n.disc, systemImage: "opticaldisc"),
        .init(title: L10n.genres, systemImage: "theatermasks.fill"),
        .init(title: L10n.played, systemImage: "checkmark.circle.fill"),
        .init(title: L10n.downloads, systemImage: "arrow.down.circle.fill"),
        .init(title: L10n.pin, systemImage: "pin.fill"),
        .init(title: L10n.tags, systemImage: "tag.fill"),
        .init(title: L10n.iconBookmark, systemImage: "bookmark.fill"),
        .init(title: L10n.iconFlag, systemImage: "flag.fill"),
        .init(title: L10n.iconGlobe, systemImage: "globe"),
        .init(title: L10n.iconCompass, systemImage: "safari.fill"),
        .init(title: L10n.iconLightning, systemImage: "bolt.fill"),
        .init(title: L10n.iconFlame, systemImage: "flame.fill"),
        .init(title: L10n.iconLeaf, systemImage: "leaf.fill"),
        .init(title: L10n.iconSun, systemImage: "sun.max.fill"),
        .init(title: L10n.iconMoon, systemImage: "moon.fill"),
        .init(title: L10n.iconGames, systemImage: "gamecontroller.fill"),
        .init(title: L10n.iconGift, systemImage: "gift.fill"),
        .init(title: L10n.iconCircle, systemImage: "circle.fill"),
        .init(title: L10n.iconTriangle, systemImage: "triangle.fill"),
        .init(title: L10n.iconDiamond, systemImage: "diamond.fill"),
    ]
}
