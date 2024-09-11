//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class ActiveSessionsViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case backgroundRefresh
        case error(JellyfinAPIError)
        case refresh
    }

    // MARK: BackgroundState

    enum BackgroundStates: Hashable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case sessions
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    var sessions: OrderedSet<SessionInfo> = []
    @Published
    final var state: State = .initial

    private var sessionTask: Task<Void, Never>?

    var deviceID: String?

    // MARK: Initializer

    init(deviceID: String? = nil) {
        self.deviceID = deviceID
    }

    // MARK: Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case .refresh, .backgroundRefresh:
            loadSessions()
            return .refreshing

        case let .error(error):
            return .error(error)
        }
    }

    // MARK: Session Management

    func loadSessions() {
        sessionTask?.cancel()

        sessionTask = Task {
            do {
                try await self.performSessionLoading()
            } catch is CancellationError {
                print("Active Sessions refresh was cancelled")
            } catch {
                await MainActor.run {
                    self.state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
    }

    private func performSessionLoading() async throws {
        let fetchedSessions = try await fetchSessions(deviceID)

        await MainActor.run {
            self.sessions = fetchedSessions
            self.state = .sessions
        }
    }

    private func fetchSessions(_ deviceID: String?) async throws -> OrderedSet<SessionInfo> {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = 960 // 960 Seconds to mirror Jellyfin-Web
        if let deviceID = deviceID {
            parameters.deviceID = deviceID
        }
        let request = Paths.getSessions(parameters: parameters)
        let response = try await userSession.client.send(request)

        return OrderedSet(response.value)
    }
}
