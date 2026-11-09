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
    private var userRecord: UserRecord?

    var user: UserDto? {
        userRecord?.value
    }

    @OptionalSharedBaseItem
    var item: BaseItemDto?

    init(log: ActivityLogEntry, user: UserDto?) {
        self.log = log
        self.userRecord = user.map { SharedUser(wrappedValue: $0).projectedValue }
        super.init()
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let session = try requireUserSession()
        try session.items.validate()
        async let fetchedItem: ItemEntry? = getItem(for: log.itemID, userSession: session)
        async let fetchedUser: UserRecord? = getUser(for: log.userID)

        let results = try? await (fetchedItem, fetchedUser)
        try session.items.validate()
        $item = results?.0
        userRecord = results?.1
    }

    private func getItem(for itemID: String?, userSession: UserSession) async throws -> ItemEntry? {
        guard let itemID else { return nil }

        return try await userSession.getFullItem(id: itemID)
    }

    private func getUser(for userID: String?) async throws -> UserRecord? {
        guard let userID else { return nil }

        return try await requireUserSession().getUser(id: userID)
    }
}
