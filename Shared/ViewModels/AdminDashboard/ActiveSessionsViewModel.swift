//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections
import SwiftUI

final class ActiveSessionsViewModel: ViewModel, Stateful {

    // MARK: - Action

    enum Action: Equatable {
        case getSessions
        case refreshSessions
    }

    // MARK: - BackgroundState

    enum BackgroundState: Hashable {
        case gettingSessions
    }

    // MARK: - State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
    }

    @Published
    final var backgroundStates: OrderedSet<BackgroundState> = []
    @Published
    final var sessions: OrderedDictionary<String, BindingBox<SessionInfo?>> = [:]
    @Published
    final var state: State = .initial

    private let activeWithinSeconds: Int = 960
    private var sessionTask: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .getSessions:
            sessionTask?.cancel()

            sessionTask = Task { [weak self] in
                await MainActor.run {
                    let _ = self?.backgroundStates.append(.gettingSessions)
                }

                do {
                    try await self?.updateSessions()
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.gettingSessions)
                }
            }
            .asAnyCancellable()

            return state
        case .refreshSessions:
            sessionTask?.cancel()

            sessionTask = Task { [weak self] in
                await MainActor.run {
                    self?.state = .initial
                }

                do {
                    try await self?.updateSessions()

                    guard let self else { return }

                    await MainActor.run {
                        self.state = .content
                    }
                } catch {
                    guard let self else { return }
                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return .initial
        }
    }

    private func updateSessions() async throws {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = activeWithinSeconds

        let request = Paths.getSessions(parameters: parameters)
        let response = try await userSession.client.send(request)

        let removedSessionIDs = sessions.keys.filter { !response.value.map(\.id).contains($0) }

        let existingIDs = sessions.keys
            .filter {
                response.value.map(\.id).contains($0)
            }
        let newSessions = response.value
            .filter {
                guard let id = $0.id else { return false }
                return !sessions.keys.contains(id)
            }
            .map { s in
                BindingBox<SessionInfo?>(
                    source: .init(
                        get: { s },
                        set: { _ in }
                    )
                )
            }

        await MainActor.run {
            for id in removedSessionIDs {
                let t = sessions[id]
                sessions[id] = nil
                t?.value = nil
            }

            for id in existingIDs {
                sessions[id]?.value = response.value.first(where: { $0.id == id })
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
}
