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
        case cancel
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
        case .cancel:
            userTask?.cancel()

            return .initial

        case let .getUsers(includeHidden, includeDisabled):
            userTask?.cancel()
            backgroundStates.append(.gettingUsers)

            userTask = Task { [weak self] in
                do {
                    try await self?.loadUsers(includeHidden: includeHidden, includeDisabled: includeDisabled)
                    await MainActor.run {
                        self?.state = .content
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

                await MainActor.run {
                    self?.backgroundStates.remove(.gettingUsers)
                }
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
                    self?.backgroundStates.remove(.deletingUsers)
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
                    self?.backgroundStates.remove(.creatingUser)
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Load Users

    private func loadUsers(includeHidden: Bool, includeDisabled: Bool) async throws {
        let request = Paths.getUsers()
        let response = try await userSession.client.send(request)

        await MainActor.run {
            var filteredUsers = response.value.sorted(using: \.name)

            if !includeHidden {
                filteredUsers = filteredUsers.filter { $0.policy?.isHidden != true }
            }

            if !includeDisabled {
                filteredUsers = filteredUsers.filter { $0.policy?.isDisabled != true }
            }

            self.users = filteredUsers
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
