//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import Pulse

@MainActor
final class UserSession {

    let server: ServerState
    let user: UserState

    private(set) lazy var items = ItemStore()

    private(set) lazy var users = UserStore()

    private(set) lazy var currentUser: UserRecord = {
        var data = user.data
        data.id = user.id
        data.name ?= user.username
        return (try? users.record(for: data)) ?? UserRecord(id: user.id, value: nil)
    }()

    var userChanges = Set<AnyCancellable>()

    var userRefresh: Task<Void, Never>?

    var itemActionErrors = PassthroughSubject<Error, Never>()

    var itemChanges: AnyCancellable?

    private var cachedClient: JellyfinClient?

    var client: JellyfinClient {
        let url = server.effectiveServerURL

        if let cachedClient, cachedClient.configuration.url == url {
            return cachedClient
        }

        // Connection changes replace only the transport, never the user session
        // or the item store retained by views and playback.
        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: url, accessToken: user.accessToken),
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        cachedClient = client

        return client
    }

    lazy var serverConnectionManager = ServerConnectionManager()

    lazy var serverSocketManager = ServerSocketManager()

    private lazy var services: [any UserSessionService] = [
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

    func willStart() async {
        observeItemChanges()
        observeUserChanges()

        for service in services {
            await service.willStart(userSession: self)
        }
    }

    func didStart() {
        for service in services {
            service.didStart(userSession: self)
        }
    }

    func willStop() {
        itemChanges = nil
        userChanges.removeAll()
        userRefresh?.cancel()
        userRefresh = nil
        for service in services.reversed() {
            service.willStop(userSession: self)
        }

        items.invalidate()
        users.invalidate()
        itemActionErrors.send(completion: .finished)
    }
}
