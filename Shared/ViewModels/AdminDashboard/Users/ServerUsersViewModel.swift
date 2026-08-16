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
        case getUsers(isHidden: Bool = false, isDisabled: Bool = false)
        case deleteUsers([String])
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingUsers
        case deletingUsers
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

        Notifications[.didChangeServerUser]
            .publisher
            .sink { [weak self] user in
                guard let self, let index = users.firstIndex(where: { $0.id == user.id }) else { return }
                users[index] = user
            }
            .store(in: &cancellables)

        Notifications[.didDeleteServerUser]
            .publisher
            .sink { [weak self] id in
                self?.users.removeAll { $0.id == id }
            }
            .store(in: &cancellables)

        Notifications[.didCreateServerUser]
            .publisher
            .sink { [weak self] user in
                self?.users.append(user)
                self?.users.sort(by: { $0.name ?? "" < $1.name ?? "" })
            }
            .store(in: &cancellables)
    }

    // MARK: - Respond to Action

    func respond(to action: Action) -> State {
        switch action {
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
        }
    }

    // MARK: - Load Users

    private func loadUsers(isHidden: Bool, isDisabled: Bool) async throws {
        let request = Paths.getUsers(isHidden: isHidden ? true : nil, isDisabled: isDisabled ? true : nil)
        let response = try await send(request)

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
        let currentUserID = try authenticatedUser.id
        let userIdsToDelete = ids.filter { $0 != currentUserID }

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

            for id in userIdsToDelete {
                Notifications[.didDeleteServerUser].post(id)
            }
        }
    }

    // MARK: - Delete User

    private func deleteUser(id: String) async throws {
        let request = Paths.deleteUser(userID: id)
        try await send(request)
    }
}
