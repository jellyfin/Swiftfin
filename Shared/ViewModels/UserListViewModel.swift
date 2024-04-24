//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Defaults
import Factory
import Foundation
import JellyfinAPI
import OrderedCollections

class UserListViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case getServers
        case signIn(UserState)
    }

    // MARK: State

    enum State: Hashable {
        case error(JellyfinAPIError)
        case initial
        case content
    }

    @Published
    var servers: OrderedDictionary<ServerState, [UserState]> = [:]

    @Published
    var lastAction: Action? = nil
    @Published
    var state: State = .initial

    @MainActor
    func respond(to action: Action) -> State {
        switch action {
        case .getServers:
            do {
                servers = try getServers()
                    .zipped(map: getUsers)
                    .reduce(into: OrderedDictionary<ServerState, [UserState]>()) { partialResult, pair in
                        partialResult[pair.0] = pair.1
                    }

                return .content
            } catch {
                return .error(.init(error.localizedDescription))
            }
        case let .signIn(user):
            Defaults[.lastServerUserID] = user.id
            Container.userSession.reset()
            Notifications[.didSignIn].post()

            return state
        }
    }

    private func getServers() throws -> [ServerState] {
        try SwiftfinStore
            .dataStack
            .fetchAll(From<ServerModel>())
            .map(\.state)
    }

    private func getUsers(for server: ServerState) throws -> [UserState] {
        guard let storedServer = try? SwiftfinStore.dataStack.fetchOne(
            From<ServerModel>(),
            Where<ServerModel>("id == %@", server.id)
        )
        else { fatalError("No stored server associated with given state server?") }

        return storedServer.users
            .map(\.state)
    }
}
