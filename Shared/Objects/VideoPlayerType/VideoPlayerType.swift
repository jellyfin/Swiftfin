//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

enum VideoPlayerType: String, CaseIterable, Displayable, Storable {

    case avPlayer
    case vlc

    var displayTitle: String {
        switch self {
        case .avPlayer:
            L10n.avPlayer
        case .vlc:
            L10n.vlc
        }
    }

    var directPlayProfiles: [DirectPlayProfile] {
        switch self {
        case .avPlayer:
            Self._avPlayerDirectPlayProfiles
        case .vlc:
            Self._vlcDirectPlayProfiles
        }
    }

    var transcodingProfiles: [TranscodingProfile] {
        switch self {
        case .avPlayer:
            Self._avPlayerTranscodingProfiles
        case .vlc:
            Self._vlcTranscodingProfiles
        }
    }

    var subtitleProfiles: [SubtitleProfile] {
        switch self {
        case .avPlayer:
            Self._avPlayerSubtitleProfiles
        case .vlc:
            Self._vlcSubtitleProfiles
        }
    }

    var remotePlaybackRoutes: [RemotePlaybackRoute] {
        switch self {
        case .avPlayer:
            RemotePlaybackRoute.supportedCases
        case .vlc:
            RemotePlaybackRoute.supportedCases
                .removing(.airPlay)
        }
    }
}
