//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
    }

    enum State {
        case content
        case initial
        case error
    }

    override init() {
        super.init()

        Task {
            await setupPublisherAssignments()
        }
    }

    @Published
    private(set) var logs: OrderedSet<LogFile> = []

    @Function(\Action.Cases.getLogs)
    private func _getLogs() async throws {
        let request = Paths.getServerLogs
        let response = try await userSession.client.send(request)

        let newLogs = OrderedSet(response.value)

        await MainActor.run {
            self.logs = newLogs
            self.state = .content
        }
    }
}
