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

final class ServerUserAdminViewModel: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: Event

    enum Event {
        case error(JellyfinAPIError)
        case updated
    }

    // MARK: Action

    enum Action: Equatable {
        case cancel
        case loadDetails
        case updatePolicy(UserPolicy)
        case updateConfiguration(UserConfiguration)
        case updateUsername(String)
    }

    // MARK: Background State

    enum BackgroundState: Hashable {
        case updating
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case content
        case updating
        case error(JellyfinAPIError)
    }

    // MARK: Published Values

    @Published
    final var state: State = .initial
    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    private(set) var user: UserDto

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var userTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: Initialize from UserDto

    init(user: UserDto) {
        self.user = user
    }

    // MARK: Respond

    func respond(to action: Action) -> State {
        switch action {
        case .cancel:
            userTask?.cancel()
            return .initial

        case .loadDetails:
            return performAction {
                try await self.loadDetails()
            }

        case let .updatePolicy(policy):
            return performAction {
                try await self.updatePolicy(policy: policy)
            }

        case let .updateConfiguration(configuration):
            return performAction {
                try await self.updateConfiguration(configuration: configuration)
            }

        case let .updateUsername(username):
            return performAction {
                try await self.updateUsername(username: username)
            }
        }
    }

    // MARK: - Perform Action

    private func performAction(action: @escaping () async throws -> Void) -> State {
        userTask?.cancel()

        userTask = Task {
            do {
                await MainActor.run {
                    _ = self.backgroundStates.append(.updating)
                }

                try await action()

                await MainActor.run {
                    self.state = .content
                    self.eventSubject.send(.updated)
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.updating)
                }
            } catch {
                let jellyfinError = JellyfinAPIError(error.localizedDescription)
                await MainActor.run {
                    self.state = .error(jellyfinError)
                    self.backgroundStates.remove(.updating)
                    self.eventSubject.send(.error(jellyfinError))
                }
            }
        }
        .asAnyCancellable()

        return .updating
    }

    // MARK: - Load User

    private func loadDetails() async throws {
        guard let userID = user.id else { return }
        let request = Paths.getUserByID(userID: userID)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.user = response.value
            self.state = .content
        }
    }

    // MARK: - Update User Policy

    private func updatePolicy(policy: UserPolicy) async throws {
        guard let userID = user.id else { return }
        let request = Paths.updateUserPolicy(userID: userID, policy)
        try await userSession.client.send(request)

        await MainActor.run {
            self.user.policy = policy
        }
    }

    // MARK: - Update User Configuration

    private func updateConfiguration(configuration: UserConfiguration) async throws {
        guard let userID = user.id else { return }
        let request = Paths.updateUserConfiguration(userID: userID, configuration)
        try await userSession.client.send(request)

        await MainActor.run {
            self.user.configuration = configuration
        }
    }

    // MARK: - Update User Name

    private func updateUsername(username: String) async throws {
        guard let userID = user.id else { return }
        var updatedUser = user
        updatedUser.name = username

        let request = Paths.updateUser(userID: userID, updatedUser)
        try await userSession.client.send(request)

        await MainActor.run {
            self.user.name = username
        }
    }
}
