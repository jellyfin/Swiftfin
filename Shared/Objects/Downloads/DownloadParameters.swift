//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

enum DownloadMethod: String, Codable, Hashable {

    case direct
    case transcode
}

struct DownloadParameters: Codable, Hashable, Storable {

    let profileType: DlnaProfileType
    let method: DownloadMethod
    var maxBitrate: PlaybackBitrate?

    let isChaptersEnabled: Bool
    let isLyricsEnabled: Bool
    let isSubtitlesEnabled: Bool
    let isTrickplayEnabled: Bool
}

extension DownloadParameters {

    @MainActor
    static var video: DownloadParameters {
        .init(
            profileType: .video,
            method: .direct,
            maxBitrate: nil,
            isChaptersEnabled: Defaults[.Downloads.isChaptersEnabled],
            isLyricsEnabled: false,
            isSubtitlesEnabled: Defaults[.Downloads.isSubtitlesEnabled],
            isTrickplayEnabled: Defaults[.Downloads.isTrickplayEnabled]
        )
    }

    @MainActor
    static var audio: DownloadParameters {
        .init(
            profileType: .audio,
            method: .direct,
            maxBitrate: nil,
            isChaptersEnabled: false,
            isLyricsEnabled: Defaults[.Downloads.isLyricsEnabled],
            isSubtitlesEnabled: false,
            isTrickplayEnabled: false
        )
    }
}
