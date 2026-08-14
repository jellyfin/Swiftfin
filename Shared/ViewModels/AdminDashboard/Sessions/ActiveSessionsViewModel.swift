//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import FactoryKit
import Foundation
import JellyfinAPI
import OrderedCollections

@MainActor
@Stateful
final class ActiveSessionsViewModel: ViewModel {

    struct Environment: WithDefaultValue {
        var activeWithinSeconds: Int?
        var showSessionType: ActiveSessionFilter
        var isPaused: Bool

        static var `default`: Self {
            .init(
                activeWithinSeconds: 900,
                showSessionType: .all,
                isPaused: false
            )
        }
    }

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
        case content
        case error
        case initial
    }

    @Published
    var environment: Environment = .default {
        didSet {
            guard environment.activeWithinSeconds != oldValue.activeWithinSeconds ||
                environment.showSessionType != oldValue.showSessionType
            else {
                return
            }

            self.background.refresh()
        }
    }

    @Published
    private(set) var sessions: OrderedDictionary<String, SessionViewModel> = [:]

    override init() {
        super.init()

        userSession?
            .serverSocketManager
            .sessions()
            .sink { [weak self] sessions in
                Task { @MainActor in
                    self?.updateSessions(sessions)
                }
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        let parameters = Paths.GetSessionsParameters(activeWithinSeconds: environment.activeWithinSeconds)
        let request = Paths.getSessions(parameters: parameters)
        let response = try await send(request)

        updateSessions(response.value)
    }

    private func updateSessions(_ incomingSessions: [SessionInfoDto]) {

        guard !environment.isPaused else {
            logger.debug("Socket updates are paused")
            return
        }

        // Reuse existing observers so ActiveSessionDetailsViews keep receiving updates
        var updatedSessions: OrderedDictionary<String, SessionViewModel> = [:]

        let filteredSessions = incomingSessions
            .filter { session in
                guard let seconds = environment.activeWithinSeconds else { return true }
                guard let date = session.lastActivityDate else { return true }
                return Date.now.timeIntervalSince(date) <= TimeInterval(seconds)
            }
            .filter { session in
                switch environment.showSessionType {
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
