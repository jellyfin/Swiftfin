//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Pulse

final class UserSession {

    let client: JellyfinClient
    let server: ServerState
    let user: UserState
    lazy var serverConnectionManager = ServerConnectionManager(userSession: self)

    private lazy var services: [any UserSessionService] = [
        serverConnectionManager,
    ]

    init(
        server: ServerState,
        user: UserState
    ) {
        self.server = server
        self.user = user

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(
                url: server.effectiveServerURL,
                accessToken: user.accessToken
            ),
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        self.client = client
    }

    @MainActor
    func start() {
        for service in services {
            service.userSessionDidStart()
        }
    }

    @MainActor
    func willStop() {
        for service in services.reversed() {
            service.userSessionWillStop()
        }
    }
}
