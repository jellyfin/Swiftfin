//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import MediaPlayer

struct NowPlayableStaticMetadata {

    let assetURL: URL?
    let mediaType: MPNowPlayingInfoMediaType
    let isLiveStream: Bool

    let title: String
    let artist: String?
    let artwork: MPMediaItemArtwork?

    let albumArtist: String?
    let albumTitle: String?
}

struct NowPlayableDynamicMetadata {

    let rate: Float
    let position: Float
    let duration: Float

    let currentLanguageOptions: [MPNowPlayingInfoLanguageOption]
    let availableLanguageOptionGroups: [MPNowPlayingInfoLanguageOptionGroup]
}
