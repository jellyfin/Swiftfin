//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension SessionInfoDto {

    var device: DeviceType {
        DeviceType(
            client: client,
            deviceName: deviceName
        )
    }

    var playMethodDisplayTitle: String? {
        guard nowPlayingItem != nil, let playState, let playMethod = playState.playMethod else { return nil }

        if let transcodingInfo {

            let isVideoDirect = transcodingInfo.isVideoDirect ?? false
            let hasVideoCodec = transcodingInfo.videoCodec != nil
            let isAudioDirect = transcodingInfo.isAudioDirect ?? false

            if isVideoDirect || hasVideoCodec, isAudioDirect {
                return L10n.remux
            } else if isVideoDirect {
                return PlayMethod.directStream.displayTitle
            }
        }

        switch playMethod {
        case .transcode:
            return PlayMethod.transcode.displayTitle
        case .directPlay, .directStream:
            return PlayMethod.directPlay.displayTitle
        }
    }
}
