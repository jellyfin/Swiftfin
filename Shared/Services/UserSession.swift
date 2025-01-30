//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreData
import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Pulse
import UIKit

final class UserSession {

    let client: JellyfinClient
    let server: ServerState
    let user: UserState

    init(
        server: ServerState,
        user: UserState
    ) {
        self.server = server
        self.user = user

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL),
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: Container.shared.pulseNetworkLogger()),
            accessToken: user.accessToken
        )

        self.client = client
    }
}

extension Container {
    var currentUserSession: Factory<UserSession?> {
        self {
            guard case let .signedIn(userId) = Defaults[.lastSignedInUserID] else { return nil }

            guard let user = try? SwiftfinStore.dataStack.fetchOne(
                From<UserModel>().where(\.$id == userId)
            ) else {
                // had last user ID but no saved user
                Defaults[.lastSignedInUserID] = .signedOut

                return nil
            }

            guard let server = user.server,
                  let _ = SwiftfinStore.dataStack.fetchExisting(server)
            else {
                fatalError("No associated server for last user")
            }

            return .init(
                server: server.state,
                user: user.state
            )
        }.cached
    }
}
