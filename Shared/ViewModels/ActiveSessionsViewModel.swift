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

    // MARK: - Action

    enum Action: Equatable {
        case backgroundRefresh
        case error(JellyfinAPIError)
        case refresh
    }

    // MARK: - BackgroundState

    enum BackgroundStates: Hashable {
        case refresh
    }

    // MARK: - State

    enum State: Hashable {
        case sessions
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    // MARK: - Published Variables

    @Published
    var sessions: OrderedSet<SessionInfo> = []
    @Published
    final var state: State = .initial

    // MARK: - Variables

    var deviceID: String?
    var activeWithinSeconds: Int
    private var sessionTask: Task<Void, Never>?

    // MARK: - Init

    init(deviceID: String? = nil, activeWithinSeconds: Int = 960) {
        self.deviceID = deviceID
        self.activeWithinSeconds = activeWithinSeconds // Defaults to 960 seconds to mirror Jellyfin-Web
    }

    // MARK: - Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case .refresh, .backgroundRefresh:
            getSessions()
            return .refreshing

        case let .error(error):
            return .error(error)
        }
    }

    // MARK: - Load Active Sessions

    func getSessions() {
        sessionTask?.cancel()

        sessionTask = Task {
            do {
                try await loadSessions()
            } catch {
                await MainActor.run {
                    state = .error(JellyfinAPIError(error.localizedDescription))
                }
            }
        }
    }

    // MARK: - Fetch Active Sessions & Handle State

    private func loadSessions() async throws {
        let fetchedSessions = try await requestSessions(deviceID)

        await MainActor.run {
            sessions = fetchedSessions
            state = .sessions
        }
    }

    // MARK: - Fetch Sessions via API

    private func requestSessions(_ deviceID: String?) async throws -> OrderedSet<SessionInfo> {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = activeWithinSeconds
        if let deviceID = deviceID {
            parameters.deviceID = deviceID
        }

        let request = Paths.getSessions(parameters: parameters)
        let response = try await userSession.client.send(request)

        return OrderedSet(response.value)
    }
}
