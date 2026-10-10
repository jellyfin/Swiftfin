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
import Logging

@MainActor
extension UserSession {

    var userData: UserDto {
        currentUser.value ?? UserDto(id: user.id)
    }

    /// Only account changes affecting library visibility require a collection refresh.
    var userLibraryChanges: AnyPublisher<Void, Never> {
        users.changes
            .compactMap { [userID = user.id] change -> UserDto? in
                guard case let .updated(data) = change, data.id == userID else { return nil }

                return data
            }
            .prepend(userData)
            .removeDuplicates {
                $0.policy == $1.policy &&
                    $0.configuration?.latestItemsExcludes == $1.configuration?.latestItemsExcludes &&
                    $0.configuration?.myMediaExcludes == $1.configuration?.myMediaExcludes
            }
            .dropFirst()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func getUser(id: String) async throws -> UserRecord {
        let request = Paths.getUserByID(userID: id)
        let response = try await send(request)
        guard response.value.id == id else { throw UserStore.StoreError.invalidUserID }

        let record = try users.record(for: response.value)
        guard record.value != nil else { throw UserStore.StoreError.userUnavailable }

        return record
    }

    func observeUserChanges() {
        userChanges.removeAll()
        userRefresh?.cancel()
        userRefresh = nil
        guard users.isActive else { return }

        // Seed the active account before views or socket messages access it.
        _ = currentUser

        userLibraryChanges
            .sink { [weak self] in
                self?.items.libraryDidChange()
            }
            .store(in: &userChanges)

        users.changes
            .sink { [weak self] change in
                guard let self, self.users.isActive,
                      case let .updated(data) = change,
                      let storedUser = StoredValues[.User.users].first(where: {
                          $0.id == data.id && $0.serverID == self.server.id
                      }) else { return }

                storedUser.updateUserData(data)
            }
            .store(in: &userChanges)

        serverSocketManager.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self, self.users.isActive, !self.userChanges.isEmpty else { return }

                switch event {
                case .connected:
                    // Recover account changes missed while disconnected or backgrounded.
                    self.userRefresh?.cancel()
                    self.userRefresh = Task { @MainActor [weak self] in
                        guard let self else { return }

                        do {
                            _ = try await self.getUser(id: self.user.id)
                        } catch is CancellationError {
                        } catch {
                            Logger.swiftfin().error("Unable to refresh current user: \(error.localizedDescription)")
                        }
                    }

                case let .message(message):
                    try? self.users.receive(message)

                default:
                    break
                }
            }
            .store(in: &userChanges)
    }
}
