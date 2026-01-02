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
            return L10n.liveTVChannel
        case .liveTvProgram:
            return L10n.liveTVProgram
        case .musicAlbum:
            return L10n.album
        case .musicArtist:
            return L10n.artist
        case .musicGenre:
            return L10n.genre
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

extension BaseItemKind {

    var pluralDisplayTitle: String {
        switch self {
        case .aggregateFolder:
            return L10n.aggregateFolders
        case .audio:
            return L10n.audio
        case .audioBook:
            return L10n.audioBooks
        case .basePluginFolder:
            return L10n.basePluginFolders
        case .book:
            return L10n.books
        case .boxSet:
            return L10n.collections
        case .channel:
            return L10n.channels
        case .channelFolderItem:
            return L10n.channelFolderItems
        case .collectionFolder:
            return L10n.collectionFolders
        case .episode:
            return L10n.episodes
        case .folder:
            return L10n.folders
        case .genre:
            return L10n.genres
        case .manualPlaylistsFolder:
            return L10n.manualPlaylistsFolders
        case .movie:
            return L10n.movies
        case .liveTvChannel:
            return L10n.liveTVChannels
        case .liveTvProgram:
            return L10n.liveTVPrograms
        case .musicAlbum:
            return L10n.albums
        case .musicArtist:
            return L10n.artists
        case .musicGenre:
            return L10n.genres
        case .musicVideo:
            return L10n.musicVideos
        case .person:
            return L10n.people
        case .photo:
            return L10n.photos
        case .photoAlbum:
            return L10n.photoAlbums
        case .playlist:
            return L10n.playlists
        case .playlistsFolder:
            return L10n.playlistsFolders
        case .program:
            return L10n.programs
        case .recording:
            return L10n.recordings
        case .season:
            return L10n.seasons
        case .series:
            return L10n.series
        case .studio:
            return L10n.studios
        case .trailer:
            return L10n.trailers
        case .tvChannel:
            return L10n.tvChannels
        case .tvProgram:
            return L10n.tvPrograms
        case .userRootFolder:
            return L10n.userRootFolders
        case .userView:
            return L10n.userViews
        case .video:
            return L10n.videos
        case .year:
            return L10n.years
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
