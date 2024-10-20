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

final class APIKeyViewModel: ViewModel, Eventful, Stateful {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case created
        case deleted
        case content
    }

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

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    // MARK: Event Publishing

    private var AuthenticationTokenTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var sessions: OrderedDictionary<String, BindingBox<AuthenticationInfo?>> = [:]
    @Published
    final var apiKeys: OrderedSet<AuthenticationInfo> = []
    @Published
    final var state: State = .initial

    func respond(to action: Action) -> State {
        switch action {
        case .getAPIKeys:
            AuthenticationTokenTask = Task {
                do {
                    try await getAPIKeys()
                    await MainActor.run {
                        self.eventSubject.send(.content)
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
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
                        self.eventSubject.send(.created)
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
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
                        self.eventSubject.send(.deleted)
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
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
        let response = try await userSession.client.send(request).value

        await MainActor.run {
            if let items = response.items {
                let sortedKeys = items.sorted { $0.appName ?? "" < $1.appName ?? "" }
                self.apiKeys = OrderedSet(sortedKeys)
            } else {
                self.apiKeys = []
            }
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

        if let existingKey = apiKeys.first(where: { $0.accessToken == key }) {
            apiKeys.remove(existingKey)
        }
    }
}
