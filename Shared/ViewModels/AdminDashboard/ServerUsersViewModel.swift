//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import IdentifiedCollections
import JellyfinAPI
import SwiftUI

final class ServerUsersViewModel: ViewModel, Eventful, Stateful, Identifiable {

    // MARK: Event

    enum Event {
        case deleted
        case error(ErrorMessage)
    }

    // MARK: Actions

    enum Action: Equatable {
        case refreshUser(String)
        case getUsers(isHidden: Bool = false, isDisabled: Bool = false)
        case deleteUsers([String])
        case appendUser(UserDto)
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingUsers
        case deletingUsers
        case appendingUsers
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(ErrorMessage)
        case initial
    }

    // MARK: Published Values

    @Published
    var backgroundStates: Set<BackgroundState> = []

    @Published
    var users: IdentifiedArrayOf<UserDto> = []

    @Published
    var state: State = .initial

    var events: AnyPublisher<Event, Never> {
        eventSubject
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var userTask: AnyCancellable?
    private var eventSubject: PassthroughSubject<Event, Never> = .init()

    // MARK: - Initializer

    override init() {
        super.init()

        Notifications[.didChangeUserProfile]
            .publisher
            .sink { userID in
                Task {
                    await self.send(.refreshUser(userID))
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
        case let .refreshUser(userID):
            userTask?.cancel()
            backgroundStates.insert(.gettingUsers)

            userTask = Task {
                do {
                    try await refreshUser(userID)

                    await MainActor.run {
                        state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.gettingUsers)
                }
            }
            .asAnyCancellable()

            return state

        case let .getUsers(isHidden, isDisabled):
            userTask?.cancel()
            backgroundStates.insert(.gettingUsers)

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

                await MainActor.run {
                    _ = self.backgroundStates.remove(.gettingUsers)
                }
            }
            .asAnyCancellable()

            return state

        case let .deleteUsers(ids):
            userTask?.cancel()
            backgroundStates.insert(.deletingUsers)

            userTask = Task {
                do {
                    try await self.deleteUsers(ids: ids)

                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.deleted)
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                        self.eventSubject.send(.error(.init(error.localizedDescription)))
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.deletingUsers)
                }
            }
            .asAnyCancellable()

            return state

        case let .appendUser(user):
            userTask?.cancel()
            backgroundStates.insert(.appendingUsers)

            userTask = Task {
                do {
                    await self.appendUser(user: user)

                    await MainActor.run {
                        self.state = .content
                        self.eventSubject.send(.deleted)
                    }
                }

                await MainActor.run {
                    _ = self.backgroundStates.remove(.appendingUsers)
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Refresh User

    private func refreshUser(_ userID: String) async throws {
        let request = Paths.getUserByID(userID: userID)
        let response = try await userSession.client.send(request)

        let newUser = response.value

        await MainActor.run {
            if let index = self.users.firstIndex(where: { $0.id == userID }) {
                self.users[index] = newUser
            }
        }
    }

    // MARK: - Load Users

    private func loadUsers(isHidden: Bool, isDisabled: Bool) async throws {
        let request = Paths.getUsers(isHidden: isHidden ? true : nil, isDisabled: isDisabled ? true : nil)
        let response = try await userSession.client.send(request)

        let newUsers = response.value
            .sorted(using: \.name)

        await MainActor.run {
            self.users = IdentifiedArray(uniqueElements: newUsers)
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
            self.users.removeAll(where: { userIdsToDelete.contains($0.id ?? "") })
        }
    }

    // MARK: - Delete User

    private func deleteUser(id: String) async throws {
        let request = Paths.deleteUser(userID: id)
        try await userSession.client.send(request)
    }

    // MARK: - Append User

    private func appendUser(user: UserDto) async {
        await MainActor.run {
            users.append(user)
            users.sort(by: { $0.name ?? "" < $1.name ?? "" })
        }
    }
}
