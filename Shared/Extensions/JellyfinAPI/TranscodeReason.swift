//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension TranscodeReason: Displayable, SystemImageable {

    var displayTitle: String {
        switch self {
        case .containerNotSupported:
            L10n.containerNotSupported
        case .videoCodecNotSupported:
            L10n.videoCodecNotSupported
        case .audioCodecNotSupported:
            L10n.audioCodecNotSupported
        case .subtitleCodecNotSupported:
            L10n.subtitleCodecNotSupported
        case .audioIsExternal:
            L10n.audioIsExternal
        case .secondaryAudioNotSupported:
            L10n.secondaryAudioNotSupported
        case .videoProfileNotSupported:
            L10n.videoProfileNotSupported
        case .videoLevelNotSupported:
            L10n.videoLevelNotSupported
        case .videoResolutionNotSupported:
            L10n.videoResolutionNotSupported
        case .videoBitDepthNotSupported:
            L10n.videoBitDepthNotSupported
        case .videoFramerateNotSupported:
            L10n.videoFramerateNotSupported
        case .refFramesNotSupported:
            L10n.refFramesNotSupported
        case .anamorphicVideoNotSupported:
            L10n.anamorphicVideoNotSupported
        case .interlacedVideoNotSupported:
            L10n.interlacedVideoNotSupported
        case .audioChannelsNotSupported:
            L10n.audioChannelsNotSupported
        case .audioProfileNotSupported:
            L10n.audioProfileNotSupported
        case .audioSampleRateNotSupported:
            L10n.audioSampleRateNotSupported
        case .audioBitDepthNotSupported:
            L10n.audioBitDepthNotSupported
        case .containerBitrateExceedsLimit:
            L10n.containerBitrateExceedsLimit
        case .videoBitrateNotSupported:
            L10n.videoBitrateNotSupported
        case .audioBitrateNotSupported:
            L10n.audioBitrateNotSupported
        case .unknownVideoStreamInfo:
            L10n.unknownVideoStreamInfo
        case .unknownAudioStreamInfo:
            L10n.unknownAudioStreamInfo
        case .directPlayError:
            L10n.directPlayError
        case .videoRangeTypeNotSupported:
            L10n.videoRangeTypeNotSupported
        case .videoCodecTagNotSupported:
            L10n.videoCodecTagNotSupported
        case .streamCountExceedsLimit:
            L10n.streamCountExceedsLimit
        }
    }

    var systemImage: String {
        switch self {
        case .containerNotSupported,
             .containerBitrateExceedsLimit,
             .directPlayError:
            "shippingbox"
        case .audioCodecNotSupported,
             .audioIsExternal,
             .secondaryAudioNotSupported,
             .audioChannelsNotSupported,
             .audioProfileNotSupported,
             .audioSampleRateNotSupported,
             .audioBitDepthNotSupported,
             .audioBitrateNotSupported,
             .unknownAudioStreamInfo:
            "speaker.wave.2"
        case .videoCodecNotSupported,
             .videoProfileNotSupported,
             .videoLevelNotSupported,
             .videoResolutionNotSupported,
             .videoBitDepthNotSupported,
             .videoFramerateNotSupported,
             .refFramesNotSupported,
             .anamorphicVideoNotSupported,
             .interlacedVideoNotSupported,
             .videoBitrateNotSupported,
             .unknownVideoStreamInfo,
             .videoCodecTagNotSupported,
             .videoRangeTypeNotSupported:
            "photo.tv"
        case .subtitleCodecNotSupported:
            "captions.bubble"
        case .streamCountExceedsLimit:
            "number.circle"
        }
    }
}
