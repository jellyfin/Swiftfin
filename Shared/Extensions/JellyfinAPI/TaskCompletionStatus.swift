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
            return L10n.taskCompleted
        case .failed:
            return L10n.taskFailed
        case .cancelled:
            return L10n.taskCancelled
        case .aborted:
            return L10n.taskAborted
        }
    }
}
