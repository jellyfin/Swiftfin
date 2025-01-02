//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class AddServerUserViewModel: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: Event

    enum Event {
        case createdNewUser(UserDto)
        case error(JellyfinAPIError)
    }

    // MARK: Actions

    enum Action: Equatable {
        case cancel
        case createUser(username: String, password: String)
    }

    // MARK: - State

    enum State: Hashable {
        case initial
        case creatingUser
        case error(JellyfinAPIError)
    }

    // MARK: Published Values

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    @Published
    final var state: State = .initial

    private var userTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            userTask?.cancel()
            return .initial
        case let .createUser(username, password):
            userTask?.cancel()

            userTask = Task {
                do {
                    let newUser = try await createUser(username: username, password: password)

                    await MainActor.run {
                        state = .initial
                        eventSubject.send(.createdNewUser(newUser))
                    }
                } catch {
                    await MainActor.run {
                        state = .error(.init(error.localizedDescription))
                        eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }
            }
            .asAnyCancellable()

            return .creatingUser
        }
    }

    // MARK: - Create User

    private func createUser(username: String, password: String) async throws -> UserDto {
        let parameters = CreateUserByName(name: username, password: password)
        let request = Paths.createUserByName(parameters)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
