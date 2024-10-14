//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension SessionInfo {

    var playMethodDisplayTitle: String? {
        guard let playState = self.playState,
              let playMethod = playState.playMethod
        else {
            return nil
        }

        if (self.transcodingInfo?.isVideoDirect ?? false || self.transcodingInfo?.videoCodec == nil) &&
            self.transcodingInfo?.isAudioDirect ?? false
        {
            return L10n.remux
        } else if self.transcodingInfo?.isVideoDirect ?? false {
            return PlayMethod.directStream.displayTitle
        } else if playMethod == .transcode {
            return PlayMethod.transcode.displayTitle
        } else if playMethod == .directStream || playMethod == .directPlay {
            return PlayMethod.directPlay.displayTitle
        }

        return nil
    }
}
