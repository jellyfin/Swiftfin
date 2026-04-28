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
import JellyfinAPI
import KeychainSwift
import OrderedCollections

@MainActor
@Stateful
final class SelectUserViewModel: ViewModel {

    @Injected(\.keychainService)
    var keychain

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
        let usersByServerID = StoredValues[.User.users]
            .reduce(into: [String: [UserState]]()) { partialResult, user in
                partialResult[user.serverID, default: []].append(user)
            }

        servers = StoredValues[.Server.servers]
            .sorted(using: \.name)
            .reduce(into: .init()) { partialResult, server in
                partialResult[server] = usersByServerID[server.id, default: []]
                    .sorted(using: \.username)
            }
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
