//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import Get
import JellyfinAPI
import Pulse

final class UserSession {

    let server: ServerState
    let user: UserState

    @MainActor
    private(set) lazy var items = ItemStore()

    @MainActor
    var itemActionErrors = PassthroughSubject<Error, Never>()

    @MainActor
    var itemChanges: AnyCancellable?

    @MainActor
    private var cachedClient: JellyfinClient?

    @MainActor
    var client: JellyfinClient {
        let url = server.effectiveServerURL

        if let cachedClient, cachedClient.configuration.url == url {
            return cachedClient
        }

        // Connection changes replace only the transport, never the user session
        // or the item store retained by views and playback.
        let accessToken = user.accessToken
        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: url, accessToken: accessToken),
            delegate: AuthenticationDelegate { [weak self] in
                guard let self else { return true }

                return await Container.shared.userSessionManager().handleUnauthorizedResponse(
                    from: self,
                    accessToken: accessToken
                )
            },
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        cachedClient = client

        return client
    }

    @MainActor
    lazy var serverConnectionManager = ServerConnectionManager()

    lazy var serverSocketManager = ServerSocketManager()

    @MainActor
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

    @MainActor
    func willStart() async {
        observeItemChanges()

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
    func willStop() {
        itemChanges = nil

        for service in services.reversed() {
            service.willStop(userSession: self)
        }

        items.invalidate()
        itemActionErrors.send(completion: .finished)
    }
}

private struct AuthenticationDelegate: APIClientDelegate {

    let onUnauthorized: () async -> Bool

    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        if case APIError.unacceptableStatusCode(401) = error, await onUnauthorized() {
            // The session has ended. Do not present its request errors over the sign-in screen.
            throw CancellationError()
        }
        return false
    }
}
