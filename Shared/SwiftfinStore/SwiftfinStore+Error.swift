//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

extension SwiftfinStore {

    enum Error: LocalizedError {
        case existingServer(State.Server)
        case existingUser(State.User)

        var title: String {
            switch self {
            case .existingServer:
                return L10n.existingServer
            case .existingUser:
                return L10n.existingUser
            }
        }

        var errorDescription: String? {
            switch self {
            case let .existingServer(server):
                return L10n.serverAlreadyConnected(server.name)
            case let .existingUser(user):
                return L10n.userAlreadySignedIn(user.username)
            }
        }
    }
}
