//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
        [
            .boxSet,
            .movie,
            .musicVideo,
            .series,
            .video,
        ]
    }
}

extension BaseItemKind: ItemFilter {

    var displayTitle: String {
        switch self {
        case .aggregateFolder:
            L10n.aggregateFolder
        case .audio:
            L10n.audio
        case .audioBook:
            L10n.audioBook
        case .basePluginFolder:
            L10n.basePluginFolder
        case .book:
            L10n.book
        case .boxSet:
            L10n.collection
        case .channel:
            L10n.channel
        case .channelFolderItem:
            L10n.channelFolderItem
        case .collectionFolder:
            L10n.collectionFolder
        case .episode:
            L10n.episode
        case .folder:
            L10n.folder
        case .genre:
            L10n.genre
        case .manualPlaylistsFolder:
            L10n.manualPlaylistsFolder
        case .movie:
            L10n.movie
        case .liveTvChannel:
            L10n.liveTVChannel
        case .liveTvProgram:
            L10n.liveTVProgram
        case .musicAlbum:
            L10n.album
        case .musicArtist:
            L10n.artist
        case .musicGenre:
            L10n.genre
        case .musicVideo:
            L10n.musicVideo
        case .person:
            L10n.person
        case .photo:
            L10n.photo
        case .photoAlbum:
            L10n.photoAlbum
        case .playlist:
            L10n.playlist
        case .playlistsFolder:
            L10n.playlistsFolder
        case .program:
            L10n.program
        case .recording:
            L10n.recording
        case .season:
            L10n.season
        case .series:
            L10n.series
        case .studio:
            L10n.studio
        case .trailer:
            L10n.trailer
        case .tvChannel:
            L10n.tvChannel
        case .tvProgram:
            L10n.tvProgram
        case .userRootFolder:
            L10n.userRootFolder
        case .userView:
            L10n.userView
        case .video:
            L10n.video
        case .year:
            L10n.year
        }
    }
}

extension BaseItemKind {

    var pluralDisplayTitle: String {
        switch self {
        case .aggregateFolder:
            L10n.aggregateFolders
        case .audio:
            L10n.audio
        case .audioBook:
            L10n.audioBooks
        case .basePluginFolder:
            L10n.basePluginFolders
        case .book:
            L10n.books
        case .boxSet:
            L10n.collections
        case .channel:
            L10n.channels
        case .channelFolderItem:
            L10n.channelFolderItems
        case .collectionFolder:
            L10n.collectionFolders
        case .episode:
            L10n.episodes
        case .folder:
            L10n.folders
        case .genre:
            L10n.genres
        case .manualPlaylistsFolder:
            L10n.manualPlaylistsFolders
        case .movie:
            L10n.movies
        case .liveTvChannel:
            L10n.liveTVChannels
        case .liveTvProgram:
            L10n.liveTVPrograms
        case .musicAlbum:
            L10n.albums
        case .musicArtist:
            L10n.artists
        case .musicGenre:
            L10n.genres
        case .musicVideo:
            L10n.musicVideos
        case .person:
            L10n.people
        case .photo:
            L10n.photos
        case .photoAlbum:
            L10n.photoAlbums
        case .playlist:
            L10n.playlists
        case .playlistsFolder:
            L10n.playlistsFolders
        case .program:
            L10n.programs
        case .recording:
            L10n.recordings
        case .season:
            L10n.seasons
        case .series:
            L10n.series
        case .studio:
            L10n.studios
        case .trailer:
            L10n.trailers
        case .tvChannel:
            L10n.tvChannels
        case .tvProgram:
            L10n.tvPrograms
        case .userRootFolder:
            L10n.userRootFolders
        case .userView:
            L10n.userViews
        case .video:
            L10n.videos
        case .year:
            L10n.years
        }
    }

    var preferredPosterDisplayType: PosterDisplayType {
        switch self {
        case .audio, .channel, .musicAlbum, .tvChannel:
            .square
        case .folder, .program, .musicVideo, .video, .userView:
            .landscape
        default:
            .portrait
        }
    }
}

extension BaseItemKind {

    /// Item types that can be identified on the server.
    static var itemIdentifiableCases: [BaseItemKind] {
        [.boxSet, .movie, .person, .series]
    }
}
