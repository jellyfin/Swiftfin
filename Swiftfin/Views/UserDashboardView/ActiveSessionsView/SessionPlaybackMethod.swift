//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

enum SessionPlaybackMethod: String, Displayable {
    case directPlay
    case remux
    case directStream
    case transcode
    case unknown

    var displayTitle: String {
        switch self {
        case .directPlay:
            L10n.directPlay
        case .remux:
            L10n.remux
        case .directStream:
            L10n.directStream
        case .transcode:
            L10n.transcode
        case .unknown:
            ""
        }
    }

    static func getDisplayPlayMethod(_ session: SessionInfo) -> SessionPlaybackMethod {
        if let transcodingInfo = session.transcodingInfo {
            if (
                transcodingInfo.isVideoDirect ?? false ||
                    transcodingInfo.videoCodec == nil
            ) &&
                transcodingInfo.isAudioDirect ?? false
            {
                return .remux
            } else if transcodingInfo.isVideoDirect ?? false {
                return .directStream
            } else if session.playState?.playMethod == .transcode {
                return .transcode
            }
        }
        if session.playState?.playMethod == .directStream {
            return .directStream
        } else if session.playState?.playMethod == .directPlay {
            return .directPlay
        }

        return .unknown
    }
}
