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
        case refresh

        var transition: Transition {
            .loop(.refreshing)
        }
    }

    enum State {
        case initial
        case error
        case refreshing
    }

    @Published
    var filter: ServerLogType? {
        didSet {
            filterLogs(filter)
        }
    }

    @Published
    private(set) var logs: OrderedSet<LogFile> = []

    // Paths.getServerLogs doesn't have filtering so keep the full list to do it locally
    private var allLogs: OrderedSet<LogFile> = []

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let request = Paths.getServerLogs
        let response = try await userSession.client.send(request)

        self.allLogs = OrderedSet(response.value)

        filterLogs(filter)
    }

    private func filterLogs(_ filter: ServerLogType?) {
        guard let filter else {
            self.logs = allLogs
            return
        }

        self.logs = allLogs.filter { $0.type == filter }
    }
}
