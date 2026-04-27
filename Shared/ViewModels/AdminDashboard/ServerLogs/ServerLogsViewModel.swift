//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import OrderedCollections
import SwiftUI

@MainActor
@Stateful
final class ServerLogsViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh(filter: ServerLogType?)

        var transition: Transition {
            .to(.initial, then: .content)
        }
    }

    enum State {
        case initial
        case error
        case content
    }

    @Published
    private(set) var logs: OrderedSet<LogFile> = []

    // MARK: - Refresh

    @Function(\Action.Cases.refresh)
    private func _refresh(_ filter: ServerLogType?) async throws {
        let request = Paths.getServerLogs
        let response = try await userSession.client.send(request)

        self.logs = OrderedSet(response.value)
            .filter { filter == nil ? true : $0.type == filter }
    }
}
