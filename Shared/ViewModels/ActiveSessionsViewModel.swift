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

extension Binding where Value: Sequence {
    
    func first(where predicate: @escaping (Value.Element) throws -> Bool) rethrows -> Binding<Value.Element?> {
        Binding<Value.Element?> {
            try? wrappedValue.first(where: predicate)
        } set: { _, _ in
            
        }
    }
}

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
    final var sessions: OrderedSet<SessionInfo> = []
    @Published
    final var state: State = .initial

    private let deviceID: String?
    private let activeWithinSeconds: Int = 960
    private var sessionTask: AnyCancellable?

    init(deviceID: String? = nil) {
        self.deviceID = deviceID
    }

    func respond(to action: Action) -> State {
        switch action {
        case .getSessions:
            sessionTask?.cancel()

            sessionTask = Task { [weak self] in
                await MainActor.run {
                    let _ = self?.backgroundStates.append(.gettingSessions)
                }

                do {
                    let newSessions = try await self?.getSessions()

                    guard let self else { return }

                    await MainActor.run {
                        self.sessions = newSessions ?? []
                    }
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
                    let newSessions = try await self?.getSessions()

                    guard let self else { return }

                    await MainActor.run {
                        self.sessions = newSessions ?? []
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

    private func getSessions() async throws -> OrderedSet<SessionInfo> {
        var parameters = Paths.GetSessionsParameters()
        parameters.activeWithinSeconds = activeWithinSeconds
        parameters.deviceID = deviceID

        let request = Paths.getSessions(parameters: parameters)
        let response = try await userSession.client.send(request)

        let newSessions = response.value.sorted {
            let isPlaying0 = $0.nowPlayingItem != nil
            let isPlaying1 = $1.nowPlayingItem != nil

            if isPlaying0 && !isPlaying1 {
                return true
            } else if !isPlaying0 && isPlaying1 {
                return false
            }

            if $0.userName != $1.userName {
                return ($0.userName ?? "") < ($1.userName ?? "")
            }

            if isPlaying0 && isPlaying1 {
                return ($0.nowPlayingItem?.name ?? "") < ($1.nowPlayingItem?.name ?? "")
            } else {
                return ($0.lastActivityDate ?? Date.now) > ($1.lastActivityDate ?? Date.now)
            }
        }

        return OrderedSet(newSessions)
    }
}
