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

// TODO: Change with PagingLibraryViewModel changes
@MainActor
final class ServerActivityViewModel: PagingLibraryViewModel<ActivityLogEntry> {

    @Published
    var hasUserId: Bool? {
        didSet {
            self.send(.refresh)
        }
    }

    @Published
    var minDate: Date? {
        didSet {
            self.send(.refresh)
        }
    }

    private(set) var users: IdentifiedArrayOf<UserDto> = []

    private var userTask: AnyCancellable?

    override func respond(to action: Action) -> State {

        switch action {
        case .refresh:
            userTask?.cancel()
            userTask = Task {
                do {
                    let users = try await getUsers()

                    await MainActor.run {
                        self.users = users
                        _ = super.respond(to: action)
                    }
                } catch {
                    await MainActor.run {
                        self.send(.error(.init(L10n.unknownError)))
                    }
                }
            }
            .asAnyCancellable()

            return .refreshing
        default:
            return super.respond(to: action)
        }
    }

    override func get(page: Int) async throws -> [ActivityLogEntry] {
        var parameters = Paths.GetLogEntriesParameters()
        parameters.limit = pageSize
        parameters.hasUserID = hasUserId
        parameters.minDate = minDate
        parameters.startIndex = page * pageSize

        let request = Paths.getLogEntries(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    private func getUsers() async throws -> IdentifiedArrayOf<UserDto> {
        let request = Paths.getUsers()
        let response = try await userSession.client.send(request)

        return IdentifiedArray(uniqueElements: response.value)
    }
}
