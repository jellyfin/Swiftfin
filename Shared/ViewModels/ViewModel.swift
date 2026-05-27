//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import Get
import JellyfinAPI
import Logging

class ViewModel: ObservableObject {

    let logger = Logger.swiftfin()

    /// The current signed-in user session, if the app is authenticated.
    @Injected(\.currentUserSession)
    var userSession: UserSession?

    var cancellables = Set<AnyCancellable>()

    private var userSessionResolverCancellable: AnyCancellable?

    init() {
        userSessionResolverCancellable = Notifications[.didChangeCurrentServerURL]
            .publisher
            .sink { [weak self] _ in
                Container.shared.userSessionManager().updateCurrentServerURL()
                self?.$userSession.resolve(reset: .scope)
            }
    }

    func requireUserSession() throws -> UserSession {
        guard let userSession else {
            logger.error("Missing user session for authenticated view model")
            Container.shared.userSessionManager().refreshCurrentSession()
            throw UserSessionError.missingCurrentSession
        }

        return userSession
    }

    var authenticatedClient: JellyfinClient {
        get throws {
            try requireUserSession().client
        }
    }

    var authenticatedServer: ServerState {
        get throws {
            try requireUserSession().server
        }
    }

    var authenticatedUser: UserState {
        get throws {
            try requireUserSession().user
        }
    }

    func send<Value: Decodable & Sendable>(_ request: Request<Value>) async throws -> Response<Value> {
        try await authenticatedClient.send(request)
    }

    func send(_ request: Request<Void>) async throws {
        try await authenticatedClient.send(request)
    }
}
