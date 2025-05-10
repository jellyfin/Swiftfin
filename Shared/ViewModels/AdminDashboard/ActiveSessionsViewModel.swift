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
        case startWebSocket // New action
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
    var backgroundStates: Set<BackgroundState> = []
    @Published
    var sessions: OrderedDictionary<String, BindingBox<SessionInfoDto?>> = [:]
    @Published
    var state: State = .initial
    // @Published
    // var socketState: JellyfinSocket.State = .idle // Added for WebSocket status monitoring

    private let activeWithinSeconds: Int = 960
    private var sessionTask: AnyCancellable?
    private var socketCancellables = Set<AnyCancellable>() // Added for WebSocket
    private var socketSubscribed = false // Added for WebSocket

    func respond(to action: Action) -> State {
        switch action {
        case .getSessions:
            sessionTask?.cancel()

            sessionTask = Task { [weak self] in
                await MainActor.run {
                    let _ = self?.backgroundStates.insert(.gettingSessions)
                }

                do {
                    try await self?.updateSessions()
                    // await self?.startWebSocket() // Automatically start WebSocket

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

                await MainActor.run {
                    let _ = self?.backgroundStates.remove(.gettingSessions)
                }
            }
            .asAnyCancellable()

            return state

        case .startWebSocket:
            Task { [weak self] in
                // await self?.startWebSocket()
            }
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

    /*
     // MARK: - WebSocket

     /// Kick-off the socket exactly once, then hook up a Combine subscriber
     /// that logs every inbound message to the console.
     @MainActor
     private func startWebSocket() async {
         // Only subscribe once
         guard !socketSubscribed else { return }
         socketSubscribed = true

         print("Starting WebSocket connection…")

         let socket = userSession.client.socket

         // 1️⃣ – state‐monitoring is exactly the same
         socket.$state
             .receive(on: RunLoop.main)
             .sink { [weak self] newState in
                 self?.socketState = newState
                 print("🛜 WebSocket state: \(newState)")

                 // Attempt to reconnect if connection fails
                 if case .error = newState {
                     Task { [weak self] in
                         try? await Task.sleep(nanoseconds: 2_000_000_000)
                         await self?.startWebSocket()
                     }
                 }

                 // When connected, send our subscription messages
                 if case .connected = newState {
                     // Subscribe to sessions
                     let sessionsStartMsg = SessionsStartMessage(data: "", messageType: .sessionsStart)
                     socket.send(.sessionsStartMessage(sessionsStartMsg))

                     // Subscribe to activity log
                     let activityLogMsg = ActivityLogEntryStartMessage(data: "", messageType: .activityLogEntryStart)
                     socket.send(.activityLogEntryStartMessage(activityLogMsg))

                     // Subscribe to scheduled tasks
                     let tasksMsg = ScheduledTasksInfoStartMessage(data: "", messageType: .scheduledTasksInfoStart)
                     socket.send(.scheduledTasksInfoStartMessage(tasksMsg))

                     print("🛜 WebSocket subscriptions sent")
                 }
             }
             .store(in: &socketCancellables)

         // 2️⃣ – Use the new start() method instead of subscribe()
         socket.start()

         // 3️⃣ – Monitor heartbeats if desired
         socket.$heartbeatCount
             .dropFirst() // Skip initial value
             .sink { count in
                 print("🛜 WebSocket heartbeat: \(count)")
             }
             .store(in: &socketCancellables)

         // 4️⃣ – now just sink the messages the same way
         socket.messages
             .handleEvents(receiveSubscription: { _ in
                 print("🛜 WebSocket subscribed successfully")
             })
             .sink { message in
                 print("🛜 WebSocket IN → \(message)")

                 switch message {
                 case let .activityLogEntryMessage(msg):
                     print("→ activityLogEntryMessage: \(msg)")

                 case let .forceKeepAliveMessage(msg):
                     print("→ forceKeepAliveMessage: \(msg)")

                 case let .generalCommandMessage(msg):
                     print("→ generalCommandMessage: \(msg)")

                 case let .libraryChangedMessage(msg):
                     print("→ libraryChangedMessage: \(msg)")

                 case let .playMessage(msg):
                     print("→ playMessage: \(msg)")

                 case let .playstateMessage(msg):
                     print("→ playstateMessage: \(msg)")

                 case let .pluginInstallationCancelledMessage(msg):
                     print("→ pluginInstallationCancelledMessage: \(msg)")

                 case let .pluginInstallationCompletedMessage(msg):
                     print("→ pluginInstallationCompletedMessage: \(msg)")

                 case let .pluginInstallationFailedMessage(msg):
                     print("→ pluginInstallationFailedMessage: \(msg)")

                 case let .pluginInstallingMessage(msg):
                     print("→ pluginInstallingMessage: \(msg)")

                 case let .pluginUninstalledMessage(msg):
                     print("→ pluginUninstalledMessage: \(msg)")

                 case let .refreshProgressMessage(msg):
                     print("→ refreshProgressMessage: \(msg)")

                 case let .restartRequiredMessage(msg):
                     print("→ restartRequiredMessage: \(msg)")

                 case let .scheduledTaskEndedMessage(msg):
                     print("→ scheduledTaskEndedMessage: \(msg)")

                 case let .scheduledTasksInfoMessage(msg):
                     print("→ scheduledTasksInfoMessage: \(msg)")

                 case let .seriesTimerCancelledMessage(msg):
                     print("→ seriesTimerCancelledMessage: \(msg)")

                 case let .seriesTimerCreatedMessage(msg):
                     print("→ seriesTimerCreatedMessage: \(msg)")

                 case let .serverRestartingMessage(msg):
                     print("→ serverRestartingMessage: \(msg)")

                 case let .serverShuttingDownMessage(msg):
                     print("→ serverShuttingDownMessage: \(msg)")

                 case let .sessionsMessage(msg):
                     print("→ sessionsMessage: \(msg)")

                 case let .syncPlayCommandMessage(msg):
                     print("→ syncPlayCommandMessage: \(msg)")

                 case let .syncPlayGroupUpdateCommandMessage(msg):
                     print("→ syncPlayGroupUpdateCommandMessage: \(msg)")

                 case let .timerCancelledMessage(msg):
                     print("→ timerCancelledMessage: \(msg)")

                 case let .timerCreatedMessage(msg):
                     print("→ timerCreatedMessage: \(msg)")

                 case let .userDataChangedMessage(msg):
                     print("→ userDataChangedMessage: \(msg)")

                 case let .userDeletedMessage(msg):
                     print("→ userDeletedMessage: \(msg)")

                 case let .userUpdatedMessage(msg):
                     print("→ userUpdatedMessage: \(msg)")

                 default:
                     break
                     // print("→ Unknown outbound message: \(message)")
                 }
             }
             .store(in: &socketCancellables)
     }*/

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
                BindingBox<SessionInfoDto?>(
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
