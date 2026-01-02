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
            return L10n.containerNotSupported
        case .videoCodecNotSupported:
            return L10n.videoCodecNotSupported
        case .audioCodecNotSupported:
            return L10n.audioCodecNotSupported
        case .subtitleCodecNotSupported:
            return L10n.subtitleCodecNotSupported
        case .audioIsExternal:
            return L10n.audioIsExternal
        case .secondaryAudioNotSupported:
            return L10n.secondaryAudioNotSupported
        case .videoProfileNotSupported:
            return L10n.videoProfileNotSupported
        case .videoLevelNotSupported:
            return L10n.videoLevelNotSupported
        case .videoResolutionNotSupported:
            return L10n.videoResolutionNotSupported
        case .videoBitDepthNotSupported:
            return L10n.videoBitDepthNotSupported
        case .videoFramerateNotSupported:
            return L10n.videoFramerateNotSupported
        case .refFramesNotSupported:
            return L10n.refFramesNotSupported
        case .anamorphicVideoNotSupported:
            return L10n.anamorphicVideoNotSupported
        case .interlacedVideoNotSupported:
            return L10n.interlacedVideoNotSupported
        case .audioChannelsNotSupported:
            return L10n.audioChannelsNotSupported
        case .audioProfileNotSupported:
            return L10n.audioProfileNotSupported
        case .audioSampleRateNotSupported:
            return L10n.audioSampleRateNotSupported
        case .audioBitDepthNotSupported:
            return L10n.audioBitDepthNotSupported
        case .containerBitrateExceedsLimit:
            return L10n.containerBitrateExceedsLimit
        case .videoBitrateNotSupported:
            return L10n.videoBitrateNotSupported
        case .audioBitrateNotSupported:
            return L10n.audioBitrateNotSupported
        case .unknownVideoStreamInfo:
            return L10n.unknownVideoStreamInfo
        case .unknownAudioStreamInfo:
            return L10n.unknownAudioStreamInfo
        case .directPlayError:
            return L10n.directPlayError
        case .videoRangeTypeNotSupported:
            return L10n.videoRangeTypeNotSupported
        case .videoCodecTagNotSupported:
            return L10n.videoCodecTagNotSupported
        case .streamCountExceedsLimit:
            return L10n.streamCountExceedsLimit
        }
    }

    var systemImage: String {
        switch self {
        case .containerNotSupported,
             .containerBitrateExceedsLimit,
             .directPlayError:
            return "shippingbox"
        case .audioCodecNotSupported,
             .audioIsExternal,
             .secondaryAudioNotSupported,
             .audioChannelsNotSupported,
             .audioProfileNotSupported,
             .audioSampleRateNotSupported,
             .audioBitDepthNotSupported,
             .audioBitrateNotSupported,
             .unknownAudioStreamInfo:
            return "speaker.wave.2"
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
            return "photo.tv"
        case .subtitleCodecNotSupported:
            return "captions.bubble"
        case .streamCountExceedsLimit:
            return "number.circle"
        }
    }
}
