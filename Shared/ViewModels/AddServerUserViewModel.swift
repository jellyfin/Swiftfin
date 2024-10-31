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
import SwiftUI

final class AddServerUserViewModel: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: Event

    enum Event {
        case created
        case error(JellyfinAPIError)
    }

    // MARK: Actions

    enum Action: Equatable {
        case createUser(username: String, password: String)
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case creatingUser
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
    }

    // MARK: Published Values

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var state: State = .initial

    private var userTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case let .createUser(username, password):
            userTask?.cancel()
            backgroundStates.append(.creatingUser)

            userTask = Task { [weak self] in
                do {
                    try await self?.createUser(username: username, password: password)
                    await MainActor.run {
                        self?.state = .content
                        self?.eventSubject.send(.created)
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

                await MainActor.run {
                    _ = self?.backgroundStates.remove(.creatingUser)
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Create User

    private func createUser(username: String, password: String) async throws {
        let parameters = CreateUserByName(name: username, password: password)
        let request = Paths.createUserByName(parameters)
        let response = try await userSession.client.send(request)
    }
}
