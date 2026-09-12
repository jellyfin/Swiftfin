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

    let server: ServerState
    let user: UserState

    @MainActor
    lazy var items: ItemStore = {
        let store = ItemStore()
        store.session = self
        return store
    }()

    lazy var client: JellyfinClient = JellyfinClient(
        configuration: .swiftfinConfiguration(
            url: server.effectiveServerURL,
            accessToken: user.accessToken
        ),
        sessionConfiguration: .swiftfin,
        sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
    )

    @MainActor
    lazy var serverConnectionManager = ServerConnectionManager()

    lazy var serverSocketManager = ServerSocketManager()

    @MainActor
    private lazy var services: [any UserSessionService] = [
        items,
        serverConnectionManager,
        serverSocketManager,
    ]

    init(
        server: ServerState,
        user: UserState
    ) {
        self.server = server
        self.user = user
    }

    @MainActor
    func willStart() async {
        for service in services {
            await service.willStart(userSession: self)
        }
    }

    @MainActor
    func didStart() {
        for service in services {
            service.didStart(userSession: self)
        }
    }

    @MainActor
    func reuseItems(from session: UserSession) {
        items = session.items
        items.session = self
    }

    @MainActor
    func willStop(preservingItems: Bool = false) {
        for service in services.reversed() {
            if preservingItems, service is ItemStore {
                continue
            }
            service.willStop(userSession: self)
        }
    }
}
