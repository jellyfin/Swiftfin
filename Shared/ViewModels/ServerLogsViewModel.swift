//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class ServerLogsViewModel: ViewModel, Stateful {

    enum Action: Equatable {
        case getLogs
    }

    enum State: Hashable {
        case content
        case initial
        case error(JellyfinAPIError)
    }

    @Published
    private(set) var logs: OrderedSet<LogFile> = []
    @Published
    final var state: State = .initial
    @Published
    final var lastAction: Action?

    func respond(to action: Action) -> State {
        switch action {
        case .getLogs:
            cancellables.removeAll()

            Task {
                do {
                    let newLogs = try await getLogs()

                    await MainActor.run {
                        self.logs = newLogs
                        self.state = .content
                    }
                } catch {
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .store(in: &cancellables)

            return .initial
        }
    }

    private func getLogs() async throws -> OrderedSet<LogFile> {
        let request = Paths.getServerLogs
        let response = try await userSession.client.send(request)

        return OrderedSet(response.value)
    }
}
