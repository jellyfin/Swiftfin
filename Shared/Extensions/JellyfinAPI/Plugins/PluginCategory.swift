//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: Patch into SDK?
enum PluginCategory: String, CaseIterable, Displayable {

    case administration = "Administration"
    case anime = "Anime"
    case authentication = "Authentication"
    case books = "Books"
    case channel = "Channel"
    case general = "General"
    case liveTV = "LiveTV"
    case metadata = "Metadata"
    case moviesAndShows = "MoviesAndShows"
    case music = "Music"
    case subtitles = "Subtitles"
    case other = "Other"

    var displayTitle: String {
        switch self {
        case .administration:
            L10n.administration
        case .anime:
            L10n.anime
        case .authentication:
            L10n.authentication
        case .books:
            L10n.books
        case .channel:
            L10n.channels
        case .general:
            L10n.general
        case .liveTV:
            L10n.liveTV
        case .metadata:
            L10n.metadata
        case .moviesAndShows:
            L10n.moviesAndShows
        case .music:
            L10n.music
        case .subtitles:
            L10n.subtitles
        case .other:
            L10n.other
        }
    }
}
