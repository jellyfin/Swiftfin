//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension TranscodingProfile {

    init(
        isBreakOnNonKeyFrames: Bool? = nil,
        conditions: [ProfileCondition]? = nil,
        context: EncodingContext? = nil,
        isCopyTimestamps: Bool? = nil,
        enableMpegtsM2TsMode: Bool? = nil,
        enableSubtitlesInManifest: Bool? = nil,
        isEstimateContentLength: Bool? = nil,
        maxAudioChannels: String? = nil,
        minSegments: Int? = nil,
        protocol: String? = nil,
        segmentLength: Int? = nil,
        transcodeSeekInfo: TranscodeSeekInfo? = nil,
        type: DlnaProfileType? = nil,
        @CommaStringBuilder<AudioCodec> audioCodecs: () -> String = { "" },
        @CommaStringBuilder<VideoCodec> videoCodecs: () -> String = { "" },
        @CommaStringBuilder<MediaContainer> containers: () -> String = { "" }
    ) {
        let audioCodecs = audioCodecs()
        let videoCodecs = videoCodecs()
        let containers = containers()

        self.init(
            audioCodec: audioCodecs.isEmpty ? nil : audioCodecs,
            isBreakOnNonKeyFrames: isBreakOnNonKeyFrames,
            conditions: conditions,
            container: containers.isEmpty ? nil : containers,
            context: context,
            isCopyTimestamps: isCopyTimestamps,
            enableMpegtsM2TsMode: enableMpegtsM2TsMode,
            enableSubtitlesInManifest: enableSubtitlesInManifest,
            isEstimateContentLength: isEstimateContentLength,
            maxAudioChannels: maxAudioChannels,
            minSegments: minSegments,
            protocol: `protocol`,
            segmentLength: segmentLength,
            transcodeSeekInfo: transcodeSeekInfo,
            type: type,
            videoCodec: videoCodecs.isEmpty ? nil : videoCodecs
        )
    }
}
