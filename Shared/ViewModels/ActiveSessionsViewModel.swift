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
        case error(JellyfinAPIError)
        case loadSessions
        case refreshSessions
    }

    // MARK: State

    enum State: Hashable {
        case initial
        case loading
        case loaded
        case refreshing
        case error(JellyfinAPIError)
    }

    @Published
    var sessions: [SessionInfo] = []

    @Published
    final var state: State = .initial

    @Published
    final var lastAction: Action? = nil

    private var timer: Timer?

    // MARK: Initialization

    override init() {
        super.init()
        Task { @MainActor in
            await self.send(.loadSessions)
        }
        Task { @MainActor in
            startRefreshing()
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: Stateful Conformance

    func respond(to action: Action) -> State {
        switch action {
        case .loadSessions:
            loadSessions()
            return .loading

        case .refreshSessions:
            refreshSessions()
            return .refreshing

        case let .error(error):
            return .error(error)
        }
    }

    func send(_ action: Action) async {
        state = await respond(to: action)
        lastAction = action
    }

    // MARK: Session Management

    private func loadSessions() {
        Task { @MainActor in
            do {
                let fetchedSessions = try await fetchSessions()
                self.sessions = fetchedSessions
                self.state = .loaded
            } catch {
                self.state = .error(JellyfinAPIError(error.localizedDescription))
            }
        }
    }

    private func refreshSessions() {
        Task { @MainActor in
            do {
                let fetchedSessions = try await fetchSessions()
                self.sessions = fetchedSessions
                self.state = .loaded
            } catch {
                self.state = .error(JellyfinAPIError(error.localizedDescription))
            }
        }
    }

    private func fetchSessions() async throws -> [SessionInfo] {
        let request = Paths.getSessions(parameters: createParameters())
        let response = try await userSession.client.send(request)
        return response.value
    }

    private func createParameters() -> Paths.GetSessionsParameters {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = 960
        return parameters
    }

    private func startRefreshing() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.handleRefreshSessions()
            }
        }
    }

    // MARK: Helper Methods

    @MainActor
    private func handleRefreshSessions() {
        Task {
            await self.send(.refreshSessions)
        }
    }
}
