//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Dispatch
import JellyfinAPI

@MainActor
@Stateful
final class ServerActivityDetailViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .loop(.refreshing)
                .whenBackground(.refreshing)
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State {
        case initial
        case error
        case refreshing
    }

    @Published
    var log: ActivityLogEntry
    @Published
    var user: UserDto?
    @Published
    var item: BaseItemDto?

    init(log: ActivityLogEntry, user: UserDto?) {
        self.log = log
        self.user = user
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async {
        async let fetchedItem: BaseItemDto? = getItem(for: log.itemID)
        async let fetchedUser: UserDto? = getUser(for: log.userID)

        let results = try? await (fetchedItem, fetchedUser)
        item = results?.0
        user = results?.1
    }

    private func getItem(for itemID: String?) async throws -> BaseItemDto? {
        guard let itemID else { return nil }

        let request = Paths.getItem(itemID: itemID)
        let response = try await userSession.client.send(request)

        return response.value
    }

    private func getUser(for userID: String?) async throws -> UserDto? {
        guard let userID else { return nil }

        let request = Paths.getUserByID(userID: userID)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
