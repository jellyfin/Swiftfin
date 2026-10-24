//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import AVFoundation
import Foundation
import MediaPlayer
import UIKit

struct NowPlayableStaticMetadata: Equatable {

    let mediaType: MPNowPlayingInfoMediaType
    let isLiveStream: Bool

    let title: String
    let artist: String?
    let artwork: MPMediaItemArtwork?

    let albumArtist: String?
    let albumTitle: String?
    let overview: String?
    let contentRating: String?
    let genre: String?

    init(
        mediaType: MPNowPlayingInfoMediaType,
        isLiveStream: Bool = false,
        title: String,
        artist: String? = nil,
        artwork: MPMediaItemArtwork? = nil,
        albumArtist: String? = nil,
        albumTitle: String? = nil,
        overview: String? = nil,
        contentRating: String? = nil,
        genre: String? = nil
    ) {
        self.mediaType = mediaType
        self.isLiveStream = isLiveStream
        self.title = title
        self.artist = artist
        self.artwork = artwork
        self.albumArtist = albumArtist
        self.albumTitle = albumTitle
        self.overview = overview
        self.contentRating = contentRating
        self.genre = genre
    }

    func update(_ info: inout [String: Any]) {
        info[MPNowPlayingInfoPropertyMediaType] = mediaType.rawValue
        info[MPNowPlayingInfoPropertyIsLiveStream] = isLiveStream
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPMediaItemPropertyArtwork] = artwork
        info[MPMediaItemPropertyAlbumArtist] = albumArtist
        info[MPMediaItemPropertyAlbumTitle] = albumTitle
        info[MPMediaItemPropertyGenre] = genre
    }

    func avMetadata(artwork image: UIImage? = nil) -> [AVMetadataItem] {
        let values: [(AVMetadataIdentifier, String?)] = [
            (.commonIdentifierTitle, title),
            (.iTunesMetadataTrackSubTitle, artist),
            (.commonIdentifierDescription, overview),
            (.iTunesMetadataContentRating, contentRating),
            (.quickTimeMetadataGenre, genre),
            (.commonIdentifierArtist, artist),
            (.commonIdentifierAlbumName, albumTitle),
            (.iTunesMetadataAlbumArtist, albumArtist),
        ]

        var result = values.compactMap { identifier, value -> AVMetadataItem? in
            guard let value, value.nilIfBlank != nil else { return nil }

            let item = AVMutableMetadataItem()
            item.identifier = identifier
            item.value = value as NSString
            item.extendedLanguageTag = "und"

            return item.copy() as? AVMetadataItem
        }

        if let data = image?.pngData() {
            let item = AVMutableMetadataItem()
            item.identifier = .commonIdentifierArtwork
            item.value = data as NSData
            item.dataType = kCMMetadataBaseDataType_PNG as String
            item.extendedLanguageTag = "und"
            result.append(item)
        }

        return result
    }
}

struct NowPlayableDynamicMetadata {

    let rate: Double
    let defaultRate: Double
    let position: Duration
    let duration: Duration?

    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]

    init(
        rate: Double = 1,
        defaultRate: Double = 1,
        position: Duration,
        duration: Duration?,
        currentLanguageOptions: [MPNowPlayingInfoLanguageOption] = [],
        availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup] = []
    ) {
        self.rate = rate
        self.defaultRate = defaultRate
        self.position = position
        self.duration = duration
        self.currentLanguageOptions = currentLanguageOptions
        self.availableLanguageOptionGroups = availableLanguageOptionGroups
    }

    func update(_ info: inout [String: Any]) {
        info[MPMediaItemPropertyPlaybackDuration] = duration.flatMap { $0 > .zero ? $0.seconds : nil }
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = position.seconds
        info[MPNowPlayingInfoPropertyPlaybackRate] = rate
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = defaultRate
        info[MPNowPlayingInfoPropertyCurrentLanguageOptions] = currentLanguageOptions
        info[MPNowPlayingInfoPropertyAvailableLanguageOptions] = availableLanguageOptionGroups
    }
}
