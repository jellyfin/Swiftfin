//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension TaskState {

    var displayTitle: String {
        switch self {
        case .idle:
            return L10n.taskStateIdle
        case .cancelling:
            return L10n.taskStateCancelling
        case .running:
            return L10n.taskStateRunning
        }
    }
}
