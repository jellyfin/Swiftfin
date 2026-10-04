//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension TimerInfoDto {

    var isScheduledRecording: Bool {
        switch status {
        case .inProgress:
            // Post-padding can keep a recording active after its program ends.
            true
        case .cancelled, .completed, .error:
            false
        default:
            (endDate ?? .distantFuture) > .now
        }
    }
}
