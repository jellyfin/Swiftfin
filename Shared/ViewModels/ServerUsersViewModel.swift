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

final class ServerUsersViewModel: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: Event

    enum Event {
        case deleted
        case created
        case error(JellyfinAPIError)
    }

    // MARK: Actions

    enum Action: Equatable {
        case getUsers(includeHidden: Bool = false, includeDisabled: Bool = false)
        case deleteUsers([String])
        case createUser(username: String, password: String)
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingUsers
        case creatingUser
        case deletingUsers
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
    final var users: [UserDto] = []
    @Published
    final var state: State = .initial

    private var userTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case let .getUsers(isHidden, isDisabled):
            userTask?.cancel()
            backgroundStates.append(.gettingUsers)

            userTask = Task {
                do {
                    try await loadUsers(isHidden: isHidden, isDisabled: isDisabled)

                    await MainActor.run {
                        state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

//                await MainActor.run {
//                    _ = self?.backgroundStates.remove(.gettingUsers)
//                }
            }
            .asAnyCancellable()

            return state

        case let .deleteUsers(ids):
            userTask?.cancel()
            backgroundStates.append(.deletingUsers)

            userTask = Task { [weak self] in
                do {
                    try await self?.deleteUsers(ids: ids)

                    await MainActor.run {
                        self?.state = .content
                        self?.eventSubject.send(.deleted)
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

                await MainActor.run {
                    _ = self?.backgroundStates.remove(.deletingUsers)
                }
            }
            .asAnyCancellable()

            return state

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

    // MARK: - Load Users

    private func loadUsers(isHidden: Bool, isDisabled: Bool) async throws {
        let request = Paths.getUsers(isHidden: isHidden ? true : nil, isDisabled: isDisabled ? true : nil)
        let response = try await userSession.client.send(request)

        let newUsers = response.value
            .sorted(using: \.name)

        await MainActor.run {
            self.users = newUsers
        }
    }

    // MARK: - Delete Users

    private func deleteUsers(ids: [String]) async throws {
        guard ids.isNotEmpty else {
            return
        }

        // Don't allow self-deletion
        let userIdsToDelete = ids.filter { $0 != userSession.user.id }

        try await withThrowingTaskGroup(of: Void.self) { group in
            for userId in userIdsToDelete {
                group.addTask {
                    try await self.deleteUser(id: userId)
                }
            }

            try await group.waitForAll()
        }

        await MainActor.run {
            self.users = self.users.filter {
                !userIdsToDelete.contains($0.id ?? "")
            }
        }
    }

    // MARK: - Delete User

    private func deleteUser(id: String) async throws {
        let request = Paths.deleteUser(userID: id)
        try await userSession.client.send(request)
    }

    // MARK: - Create User

    private func createUser(username: String, password: String) async throws {
        let parameters = CreateUserByName(name: username, password: password)
        let request = Paths.createUserByName(parameters)
        let response = try await userSession.client.send(request)

        await MainActor.run {
            self.users.append(response.value)
        }
    }
}
