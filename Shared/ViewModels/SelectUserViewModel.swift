//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import CoreStore
import Foundation
import JellyfinAPI
import KeychainSwift
import OrderedCollections

@MainActor
@Stateful
final class SelectUserViewModel: ViewModel {

    @CasePathable
    enum Action {
        case deleteUsers(Set<UserState>)
        case error
        case getServers
        case signIn(UserState, pin: String)
    }

    enum Event {
        case error
        case signedIn(UserState)
    }

    @Published
    private(set) var servers: OrderedDictionary<ServerState, [UserState]> = [:]

    @Function(\Action.Cases.deleteUsers)
    private func _deleteUsers(_ users: Set<UserState>) async throws {
        for user in users {
            try user.delete()
        }

        try await _getServers()
    }

    @Function(\Action.Cases.getServers)
    private func _getServers() async throws {
        let newServers = try SwiftfinStore
            .dataStack
            .fetchAll(From<ServerModel>())
            .map(\.state)
            .sorted(using: \.name)
            .zipped(map: getUsers)
            .reduce(into: OrderedDictionary<ServerState, [UserState]>()) { partialResult, pair in
                partialResult[pair.0] = pair.1
            }

        servers = newServers
    }

    private func getUsers(for server: ServerState) throws -> [UserState] {
        guard let storedServer = try? dataStack.fetchOne(From<ServerModel>().where(\.$id == server.id)) else {
            logger.critical(
                "Unable to find server for users",
                metadata: [
                    "serverName": .string(server.name),
                ]
            )
            throw ErrorMessage(L10n.unknownError)
        }

        return storedServer.users
            .map(\.state)
    }

    @Function(\Action.Cases.signIn)
    private func _signIn(_ user: UserState, _ pin: String) throws {
        if user.accessPolicy == .requirePin, let storedPin = keychain.get("\(user.id)-pin") {
            guard pin == storedPin else {
                throw ErrorMessage(L10n.incorrectPinForUser(user.username))
            }
        }

        events.send(.signedIn(user))
    }
}
