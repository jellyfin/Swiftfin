//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

@MainActor
@Stateful
final class ActiveSessionsViewModel: ViewModel {

    @CasePathable
    enum Action {
        case refresh

        var transition: Transition {
            .to(.initial, then: .content)
                .whenBackground(.refreshing)
        }
    }

    enum BackgroundState {
        case refreshing
    }

    enum State {
        case initial
        case error
        case content
    }

    @Published
    var activeWithinSeconds: Int? = 900 {
        didSet {
            refresh()
        }
    }

    @Published
    var showSessionType: ActiveSessionFilter = .all {
        didSet {
            refresh()
        }
    }

    @Published
    private(set) var sessions: OrderedDictionary<String, SessionViewModel> = [:]

    @Published
    var isPaused = false

    override init() {
        super.init()

        guard let socket = userSession?.socket else { return }

        socket
            .subscribe(.sessions, delay: .seconds(0), interval: .seconds(2))
            .store(in: &cancellables)

        socket.events
            .compactMap { event -> [SessionInfoDto]? in
                guard case let .message(.sessionsMessage(msg)) = event else { return nil }
                return msg.data
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessions in
                Task { @MainActor in
                    guard let self else { return }
                    self.updateSessions(sessions)
                }
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let parameters = Paths.GetSessionsParameters(activeWithinSeconds: activeWithinSeconds)
        let request = Paths.getSessions(parameters: parameters)
        let response = try await userSession.client.send(request)

        updateSessions(response.value)
    }

    private func updateSessions(_ incomingSessions: [SessionInfoDto]) {

        // Disable refreshing when menus are presented
        guard !isPaused else {
            logger.debug("Socket updates are paused")
            return
        }

        // Reuse existing observers so ActiveSessionDetailsViews keep receiving updates
        var updatedSessions: OrderedDictionary<String, SessionViewModel> = [:]

        let filteredSessions = incomingSessions
            // Filter to sessions within the timeframe
                .filter { session in
                    guard let seconds = activeWithinSeconds else { return true }
                    guard let date = session.lastActivityDate else { return true }
                    return Date.now.timeIntervalSince(date) <= TimeInterval(seconds)
                }
                // Filter to sessions that match our type
                .filter { session in
                    switch showSessionType {
                    case .all:
                        true
                    case .active:
                        session.nowPlayingItem != nil
                    case .inactive:
                        session.nowPlayingItem == nil
                    }
                }
                .sorted()

        for session in filteredSessions {
            guard let id = session.id else { continue }

            if let existing = sessions[id] {
                existing.session = session
                updatedSessions[id] = existing
            } else {
                updatedSessions[id] = SessionViewModel(session: session)
            }
        }

        sessions = updatedSessions
    }
}
