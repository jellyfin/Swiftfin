//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension BaseItemKind: SupportedCaseIterable {

    /// The base supported cases for media navigation.
    /// This differs from media viewing, which may include
    /// `.episode`.
    ///
    /// These is the *base* supported cases and other objects
    /// like `LibararyParent` may have additional supported
    /// cases for querying a library.
    static var supportedCases: [BaseItemKind] {
        [.movie, .series, .boxSet, .playlist]
    }
}

extension BaseItemKind: ItemFilter {

    var displayTitle: String {
        switch self {
        case .aggregateFolder:
            return L10n.aggregateFolder
        case .audio:
            return L10n.audio
        case .audioBook:
            return L10n.audioBook
        case .basePluginFolder:
            return L10n.basePluginFolder
        case .book:
            return L10n.book
        case .boxSet:
            return L10n.collection
        case .channel:
            return L10n.channel
        case .channelFolderItem:
            return L10n.channelFolderItem
        case .collectionFolder:
            return L10n.collectionFolder
        case .episode:
            return L10n.episode
        case .folder:
            return L10n.folder
        case .genre:
            return L10n.genre
        case .manualPlaylistsFolder:
            return L10n.manualPlaylistsFolder
        case .movie:
            return L10n.movie
        case .liveTvChannel:
            return L10n.liveTvChannel
        case .liveTvProgram:
            return L10n.liveTvProgram
        case .musicAlbum:
            return L10n.musicAlbum
        case .musicArtist:
            return L10n.musicArtist
        case .musicGenre:
            return L10n.musicGenre
        case .musicVideo:
            return L10n.musicVideo
        case .person:
            return L10n.person
        case .photo:
            return L10n.photo
        case .photoAlbum:
            return L10n.photoAlbum
        case .playlist:
            return L10n.playlist
        case .playlistsFolder:
            return L10n.playlistsFolder
        case .program:
            return L10n.program
        case .recording:
            return L10n.recording
        case .season:
            return L10n.season
        case .series:
            return L10n.series
        case .studio:
            return L10n.studio
        case .trailer:
            return L10n.trailer
        case .tvChannel:
            return L10n.tvChannel
        case .tvProgram:
            return L10n.tvProgram
        case .userRootFolder:
            return L10n.userRootFolder
        case .userView:
            return L10n.userView
        case .video:
            return L10n.video
        case .year:
            return L10n.year
        }
    }
}
