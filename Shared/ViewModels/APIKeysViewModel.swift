//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

// TODO: for APIKey updating, could temp set new APIKeys

final class APIKeysViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case getAPIKeys
        case createAPIKey(name: String)
        case deleteAPIKey(key: String)
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case error(JellyfinAPIError)
        case content
    }

    // MARK: Event Publishing

    private var AuthenticationTokenTask: AnyCancellable?

    // MARK: Published Variables

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var apiKeys: [AuthenticationInfo?] = []
    @Published
    final var state: State = .initial

    // MARK: Action Responses

    func respond(to action: Action) -> State {
        switch action {
        case .getAPIKeys:
            AuthenticationTokenTask = Task {
                do {
                    try await getAPIKeys()
                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

        case let .createAPIKey(name):
            AuthenticationTokenTask = Task {
                do {
                    try await createAPIKey(name: name)
                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

        case let .deleteAPIKey(key):
            AuthenticationTokenTask = Task {
                do {
                    try await deleteAPIKey(key: key)
                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()
        }
        return state
    }

    private func getAPIKeys() async throws {
        let request = Paths.getKeys
        let response = try await userSession.client.send(request)

        guard let items = response.value.items else { return }

        await MainActor.run {
            self.apiKeys = items
        }
    }

    private func createAPIKey(name: String) async throws {
        let request = Paths.createKey(app: name)
        try await userSession.client.send(request).value

        try await getAPIKeys()
    }

    private func deleteAPIKey(key: String) async throws {
        let request = Paths.revokeKey(key: key)
        try await userSession.client.send(request)

        try await getAPIKeys()
    }
}
