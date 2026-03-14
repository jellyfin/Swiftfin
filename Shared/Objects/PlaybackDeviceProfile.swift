//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct CustomDeviceProfile: Hashable, Storable {

    let type: DlnaProfileType
    var useAsTranscodingProfile: Bool

    var audio: [AudioCodec]
    var video: [VideoCodec]
    var container: [MediaContainer]

    init(
        type: DlnaProfileType,
        useAsTranscodingProfile: Bool = false,
        audio: [AudioCodec] = [],
        video: [VideoCodec] = [],
        container: [MediaContainer] = []
    ) {
        self.type = type
        self.useAsTranscodingProfile = useAsTranscodingProfile
        self.audio = audio
        self.video = video
        self.container = container
    }

    var directPlayProfile: DirectPlayProfile {
        switch type {
        case .video:
            return DirectPlayProfile(
                type: type,
                audioCodecs: audio,
                videoCodecs: video,
                containers: container
            )
        default:
            assertionFailure("Only Video is currently supported.")
            return DirectPlayProfile()
        }
    }

    var transcodingProfile: TranscodingProfile {
        switch type {
        case .video:
            return TranscodingProfile(
                isBreakOnNonKeyFrames: true,
                context: .streaming,
                maxAudioChannels: "8",
                minSegments: 2,
                protocol: MediaStreamProtocol.hls,
                type: .video
            ) {
                audio
            } videoCodecs: {
                video
            } containers: {
                container
            }
        default:
            assertionFailure("Only Video is currently supported.")
            return TranscodingProfile(audioCodec: nil)
        }
    }
}
