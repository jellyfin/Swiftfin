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

@MainActor
@Stateful
final class ServerUsersViewModel: ViewModel, Identifiable {

    @CasePathable
    enum Action {
        case refreshUser(String)
        case getUsers(isHidden: Bool, isDisabled: Bool)
        case deleteUsers([String])
        case appendUser(UserDto)

        var transition: Transition {
            switch self {
            case .refreshUser, .getUsers:
                .to(.content)
                    .whenBackground(.gettingUsers)
                    .onRepeat(.cancel)
            case .deleteUsers:
                .to(.content)
                    .whenBackground(.deletingUsers)
                    .onRepeat(.cancel)
            case .appendUser:
                .to(.content)
                    .whenBackground(.appendingUsers)
                    .onRepeat(.cancel)
            }
        }
    }

    enum BackgroundState {
        case gettingUsers
        case deletingUsers
        case appendingUsers
    }

    enum Event {
        case deleted
    }

    enum State {
        case content
        case error
        case initial
    }

    @Published
    var users: IdentifiedArrayOf<UserDto> = []

    // MARK: - Initializer

    override init() {
        super.init()

        Notifications[.didChangeUserProfile]
            .publisher
            .sink { [weak self] userID in
                self?.refreshUser(userID)
            }
            .store(in: &cancellables)
    }

    // MARK: - Refresh User

    @Function(\Action.Cases.refreshUser)
    private func _refreshUser(_ userID: String) async throws {
        await cancel()

        let request = Paths.getUserByID(userID: userID)
        let response = try await send(request)

        let newUser = response.value

        if let index = users.firstIndex(where: { $0.id == userID }) {
            users[index] = newUser
        }
    }

    // MARK: - Load Users

    @Function(\Action.Cases.getUsers)
    private func _getUsers(_ isHidden: Bool, _ isDisabled: Bool) async throws {
        await cancel()

        let request = Paths.getUsers(isHidden: isHidden ? true : nil, isDisabled: isDisabled ? true : nil)
        let response = try await send(request)

        let newUsers = response.value
            .sorted(using: \.name)

        users = IdentifiedArray(uniqueElements: newUsers)
    }

    // MARK: - Delete Users

    @Function(\Action.Cases.deleteUsers)
    private func _deleteUsers(_ ids: [String]) async throws {
        await cancel()

        guard ids.isNotEmpty else {
            events.send(.deleted)
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

        users.removeAll(where: { userIdsToDelete.contains($0.id ?? "") })
        events.send(.deleted)
    }

    // MARK: - Delete User

    private func deleteUser(id: String) async throws {
        let request = Paths.deleteUser(userID: id)
        try await send(request)
    }

    // MARK: - Append User

    @Function(\Action.Cases.appendUser)
    private func _appendUser(_ user: UserDto) async {
        await cancel()

        users.append(user)
        users.sort(by: { $0.name ?? "" < $1.name ?? "" })
        events.send(.deleted)
    }
}
