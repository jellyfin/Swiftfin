//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

enum NowPlayableError: LocalizedError {

    case noRegisteredCommands
    case cannotSetCategory(Error)
    case cannotActivateSession(Error)
    case cannotReactivateSession(Error)

    var errorDescription: String? {
        switch self {
        case .noRegisteredCommands:
            return "At least one remote command must be registered."
        case let .cannotSetCategory(error):
            return "The audio session category could not be set:\n\(error)"
        case let .cannotActivateSession(error):
            return "The audio session could not be activated:\n\(error)"
        case let .cannotReactivateSession(error):
            return "The audio session could not be resumed after interruption:\n\(error)"
        }
    }
}
