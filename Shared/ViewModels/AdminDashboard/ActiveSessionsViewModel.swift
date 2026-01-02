//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

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
    private(set) var sessions: OrderedDictionary<String, BindingBox<SessionInfoDto?>> = [:]

    @Function(\Action.Cases.refresh)
    private func _refresh() async throws {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = activeWithinSeconds

        let request = Paths.getSessions(parameters: parameters)
        let response = try await userSession.client.send(request)

        let filteredSessions: [SessionInfoDto]
        switch showSessionType {
        case .all:
            filteredSessions = response.value
        case .active:
            filteredSessions = response.value.filter { $0.nowPlayingItem != nil }
        case .inactive:
            filteredSessions = response.value.filter { $0.nowPlayingItem == nil }
        }

        let removedSessionIDs = sessions.keys.filter { !filteredSessions.map(\.id).contains($0) }

        let existingIDs = sessions.keys
            .filter {
                filteredSessions.map(\.id).contains($0)
            }
        let newSessions = filteredSessions
            .filter {
                guard let id = $0.id else { return false }
                return !sessions.keys.contains(id)
            }
            .map { s in
                BindingBox<SessionInfoDto?>(
                    source: .init(
                        get: { s },
                        set: { _ in }
                    )
                )
            }

        for id in removedSessionIDs {
            let t = sessions[id]
            sessions[id] = nil
            t?.value = nil
        }

        for id in existingIDs {
            sessions[id]?.value = filteredSessions.first(where: { $0.id == id })
        }

        for session in newSessions {
            guard let id = session.value?.id else { continue }

            sessions[id] = session
        }

        sessions.sort { x, y in
            let xs = x.value.value
            let ys = y.value.value

            let isPlaying0 = xs?.nowPlayingItem != nil
            let isPlaying1 = ys?.nowPlayingItem != nil

            if isPlaying0 && !isPlaying1 {
                return true
            } else if !isPlaying0 && isPlaying1 {
                return false
            }

            if xs?.userName != ys?.userName {
                return (xs?.userName ?? "") < (ys?.userName ?? "")
            }

            if isPlaying0 && isPlaying1 {
                return (xs?.nowPlayingItem?.name ?? "") < (ys?.nowPlayingItem?.name ?? "")
            } else {
                return (xs?.lastActivityDate ?? Date.now) > (ys?.lastActivityDate ?? Date.now)
            }
        }
    }
}
