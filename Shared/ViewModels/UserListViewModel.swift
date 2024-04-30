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
        case deleteUsers([UserState])
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
    var state: State = .initial

    @MainActor
    func respond(to action: Action) -> State {
        switch action {
        case let .deleteUsers(users):
            do {
                for user in users {
                    try delete(user: user)
                }

                return state
            } catch {
                return .error(.init(error.localizedDescription))
            }
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
            Defaults[.lastSignedInUserID] = user.id
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

    private func delete(user: UserState) throws {
        guard let storedUser = try? SwiftfinStore.dataStack.fetchOne(
            From<UserModel>(),
            [Where<UserModel>("id == %@", user.id)]
        ) else {
            logger.error("Unable to find user to delete")
            return
        }

        let transaction = SwiftfinStore.dataStack.beginUnsafe()
        transaction.delete(storedUser)

        try transaction.commitAndWait()
    }
}
