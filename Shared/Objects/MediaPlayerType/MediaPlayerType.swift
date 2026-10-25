//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

enum MediaPlayerType: String, CaseIterable, Displayable, Storable {

    case avPlayer
    case mpv

    var displayTitle: String {
        switch self {
        case .avPlayer:
            L10n.avPlayer
        case .mpv:
            L10n.mpv
        }
    }

    var directPlayProfiles: [DirectPlayProfile] {
        switch self {
        case .avPlayer:
            Self._avPlayerDirectPlayProfiles
        case .mpv:
            Self._mpvDirectPlayProfiles
        }
    }

    var transcodingProfiles: [TranscodingProfile] {
        switch self {
        case .avPlayer:
            Self._avPlayerTranscodingProfiles
        case .mpv:
            Self._mpvTranscodingProfiles
        }
    }

    var subtitleProfiles: [SubtitleProfile] {
        switch self {
        case .avPlayer:
            Self._avPlayerSubtitleProfiles
        case .mpv:
            Self._mpvSubtitleProfiles
        }
    }

    @MainActor
    func makePlayer() -> any MediaPlayer {
        switch self {
        case .avPlayer:
            AVMediaPlayer()
        case .mpv:
            MPVMediaPlayer()
        }
    }
}
