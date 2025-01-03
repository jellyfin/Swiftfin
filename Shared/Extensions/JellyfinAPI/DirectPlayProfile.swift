//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DirectPlayProfile {

    init(
        type: DlnaProfileType,
        @CommaStringBuilder<AudioCodec> audioCodecs: () -> String = { "" },
        @CommaStringBuilder<VideoCodec> videoCodecs: () -> String = { "" },
        @CommaStringBuilder<MediaContainer> containers: () -> String = { "" }
    ) {
        let audioCodecs = audioCodecs()
        let videoCodecs = videoCodecs()
        let containers = containers()

        self.init(
            audioCodec: audioCodecs.isEmpty ? nil : audioCodecs,
            container: containers.isEmpty ? nil : containers,
            type: type,
            videoCodec: videoCodecs.isEmpty ? nil : videoCodecs
        )
    }

    init(
        type: DlnaProfileType,
        audioCodecs: [AudioCodec],
        videoCodecs: [VideoCodec],
        containers: [MediaContainer]
    ) {
        self.init(
            type: type,
            audioCodecs: { audioCodecs },
            videoCodecs: { videoCodecs },
            containers: { containers }
        )
    }
}
