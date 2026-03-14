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
        case getLogs

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
    private(set) var logs: OrderedSet<LogFile> = []

    @Function(\Action.Cases.getLogs)
    private func _getLogs() async throws {
        let request = Paths.getServerLogs
        let response = try await userSession.client.send(request)
        let newLogs = OrderedSet(response.value)
        self.logs = newLogs
    }
}
