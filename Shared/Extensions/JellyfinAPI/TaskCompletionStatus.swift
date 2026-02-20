//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension TaskCompletionStatus: Displayable {

    var displayTitle: String {
        switch self {
        case .completed:
            L10n.taskCompleted
        case .failed:
            L10n.taskFailed
        case .cancelled:
            L10n.taskCancelled
        case .aborted:
            L10n.taskAborted
        }
    }
}
