//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

enum StreamType: String, Displayable {

    case direct
    case transcode
    case hls

    var displayTitle: String {
        switch self {
        case .direct:
            return L10n.direct
        case .transcode:
            return L10n.transcode
        case .hls:
            return "HLS"
        }
    }
}
