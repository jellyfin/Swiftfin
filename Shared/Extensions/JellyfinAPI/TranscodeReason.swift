//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension TranscodeReason {
    var description: String {
        switch self {
        case .containerNotSupported:
            return "The container format is not supported"
        case .videoCodecNotSupported:
            return "The video codec is not supported"
        case .audioCodecNotSupported:
            return "The audio codec is not supported"
        case .subtitleCodecNotSupported:
            return "The subtitle codec is not supported"
        case .audioIsExternal:
            return "The audio track is external and requires transcoding"
        case .secondaryAudioNotSupported:
            return "Secondary audio is not supported"
        case .videoProfileNotSupported:
            return "The video profile is not supported"
        case .videoLevelNotSupported:
            return "The video level is not supported"
        case .videoResolutionNotSupported:
            return "The video resolution is not supported"
        case .videoBitDepthNotSupported:
            return "The video bit depth is not supported"
        case .videoFramerateNotSupported:
            return "The video framerate is not supported"
        case .refFramesNotSupported:
            return "The number of reference frames is not supported"
        case .anamorphicVideoNotSupported:
            return "Anamorphic video is not supported"
        case .interlacedVideoNotSupported:
            return "Interlaced video is not supported"
        case .audioChannelsNotSupported:
            return "The number of audio channels is not supported"
        case .audioProfileNotSupported:
            return "The audio profile is not supported"
        case .audioSampleRateNotSupported:
            return "The audio sample rate is not supported"
        case .audioBitDepthNotSupported:
            return "The audio bit depth is not supported"
        case .containerBitrateExceedsLimit:
            return "The container bitrate exceeds the allowed limit"
        case .videoBitrateNotSupported:
            return "The video bitrate is not supported"
        case .audioBitrateNotSupported:
            return "The audio bitrate is not supported"
        case .unknownVideoStreamInfo:
            return "The video stream information is unknown"
        case .unknownAudioStreamInfo:
            return "The audio stream information is unknown"
        case .directPlayError:
            return "An error occurred during direct play"
        case .videoRangeTypeNotSupported:
            return "The video range type is not supported"
        }
    }
}
