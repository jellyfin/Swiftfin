//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import MediaPlayer

struct NowPlayableStaticMetadata {

    let mediaType: MPNowPlayingInfoMediaType
    let isLiveStream: Bool

    let title: String
    let artist: String?
    let artwork: MPMediaItemArtwork?

    let albumArtist: String?
    let albumTitle: String?

    init(
        mediaType: MPNowPlayingInfoMediaType,
        isLiveStream: Bool = false,
        title: String,
        artist: String? = nil,
        artwork: MPMediaItemArtwork? = nil,
        albumArtist: String? = nil,
        albumTitle: String? = nil
    ) {
        self.mediaType = mediaType
        self.isLiveStream = isLiveStream
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.albumArtist = albumArtist
        self.albumTitle = albumTitle
    }
}

struct NowPlayableDynamicMetadata {

    let rate: Float
    let position: Duration
    let duration: Duration

    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]

    init(
        rate: Float = 1,
        position: Duration,
        duration: Duration,
        currentLanguageOptions: [MPNowPlayingInfoLanguageOption] = [],
        availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup] = []
    ) {
        self.rate = rate
        self.position = position
        self.duration = duration
        self.currentLanguageOptions = currentLanguageOptions
        self.availableLanguageOptionGroups = availableLanguageOptionGroups
    }
}
