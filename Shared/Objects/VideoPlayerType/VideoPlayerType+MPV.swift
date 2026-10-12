//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension VideoPlayerType {

    // MARK: - Direct Play

    /// VLC's, plus TrueHD: mpv decodes it, or plays it as spatial audio, instead of the server transcoding it.
    static var _mpvDirectPlayProfiles: [DirectPlayProfile] {
        _vlcDirectPlayProfiles.map { profile in
            var profile = profile
            profile.audioCodec = [profile.audioCodec, AudioCodec.truehd.rawValue]
                .compactMap(\.self)
                .joined(separator: ",")
            return profile
        }
    }
}
