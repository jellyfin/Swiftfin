//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import SwiftUI

@MainActor
@Stateful
final class ServerUsersViewModel: ViewModel, Identifiable {

    @CasePathable
    enum Action {
        case getUsers(isHidden: Bool, isDisabled: Bool)
        case deleteUsers([String])
        case appendUser(UserDto)

        var transition: Transition {
            switch self {
            case .getUsers:
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
    private var userRecords: [UserRecord] = []
    @Published
    private var isHiddenFilterActive = false
    @Published
    private var isDisabledFilterActive = false

    var users: [UserDto] {
        userRecords.compactMap(\.value)
            .filter { !isHiddenFilterActive || $0.policy?.isHidden == true }
            .filter { !isDisabledFilterActive || $0.policy?.isDisabled == true }
            .sorted(using: \.name)
    }

    // MARK: - Load Users

    @Function(\Action.Cases.getUsers)
    private func _getUsers(_ isHidden: Bool, _ isDisabled: Bool) async throws {
        await cancel()

        let session = try requireUserSession()
        let response = try await session.send(Paths.getUsers())

        isHiddenFilterActive = isHidden
        isDisabledFilterActive = isDisabled
        userRecords = try response.value.map { try session.users.record(for: $0) }
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

        userRecords.removeAll(where: { userIdsToDelete.contains($0.id) })
        events.send(.deleted)
    }

    // MARK: - Delete User

    private func deleteUser(id: String) async throws {
        let session = try requireUserSession()
        let request = Paths.deleteUser(userID: id)
        try await session.send(request)
        session.users.delete(id: id)
    }

    // MARK: - Append User

    @Function(\Action.Cases.appendUser)
    private func _appendUser(_ user: UserDto) async throws {
        await cancel()

        let session = try requireUserSession()
        let record = try session.users.record(for: user)
        if !userRecords.contains(where: { $0.id == record.id }) {
            userRecords.append(record)
        }
        events.send(.deleted)
    }
}
