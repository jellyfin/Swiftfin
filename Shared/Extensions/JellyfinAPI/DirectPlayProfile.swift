//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DirectPlayProfile {

    init(
        type: DlnaProfileType,
        @ArrayBuilder<AudioCodec> audioCodecs: () -> [AudioCodec] = { [] },
        @ArrayBuilder<VideoCodec> videoCodecs: () -> [VideoCodec] = { [] },
        @ArrayBuilder<MediaContainer> containers: () -> [MediaContainer] = { [] }
    ) {
        let audioCodecs = audioCodecs().map(\.rawValue).joined(separator: ",")
        let videoCodecs = videoCodecs().map(\.rawValue).joined(separator: ",")
        let containers = containers().map(\.rawValue).joined(separator: ",")

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
