//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension PlaybackCompatibility {

    enum Video {

        // MARK: - Compatibility Profiles

        @ArrayBuilder<DirectPlayProfile>
        static var compatibilityDirectPlayProfile: [DirectPlayProfile] {
            DirectPlayProfile(type: .video) {
                AudioCodec.aac
            } videoCodecs: {
                VideoCodec.h264
            } containers: {
                MediaContainer.mp4
            }
        }

        @ArrayBuilder<TranscodingProfile>
        static var compatibilityTranscodingProfile: [TranscodingProfile] {
            TranscodingProfile(
                isBreakOnNonKeyFrames: true,
                context: .streaming,
                maxAudioChannels: "8",
                minSegments: 2,
                protocol: MediaStreamProtocol.hls,
                type: .video
            ) {
                AudioCodec.aac
            } videoCodecs: {
                VideoCodec.h264
            } containers: {
                MediaContainer.mp4
            }
        }

        // MARK: - Direct Profile

        @ArrayBuilder<DirectPlayProfile>
        static var forcedDirectPlayProfile: [DirectPlayProfile] {
            DirectPlayProfile(type: .video)
        }
    }
}
