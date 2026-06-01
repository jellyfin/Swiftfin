//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import Logging

@MainActor
final class SessionMessageObserver: ObservableObject {

    private let logger = Logger.swiftfin()

    private var cancellables = Set<AnyCancellable>()
    private var socketSession: JellyfinSocket.Session?
    private var task: Task<Void, Never>?

    init() {
        Notifications[.didSignIn]
            .publisher
            .sink { [weak self] _ in
                self?.start()
            }
            .store(in: &cancellables)

        Notifications[.didRestoreUserSession]
            .publisher
            .sink { [weak self] _ in
                self?.start()
            }
            .store(in: &cancellables)

        Notifications[.didSignOut]
            .publisher
            .sink { [weak self] _ in
                self?.stop()
            }
            .store(in: &cancellables)
    }

    func start() {
        stop()

        guard let userSession = Container.shared.currentUserSession() else {
            return
        }

        let socketSession = userSession.client
            .socket(
                supportsMediaControl: true,
                supportedCommands: [.displayMessage],
                playableMediaTypes: []
            )
            .connect()

        self.socketSession = socketSession

        task = Task { [weak self, socketSession] in
            do {
                for try await event in socketSession.events {
                    self?.handle(event)
                }
            } catch is CancellationError {
                return
            } catch {
                self?.logger.error("Session message socket disconnected: \(error.localizedDescription)")
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil

        socketSession?.disconnect()
        socketSession = nil
    }

    private func handle(_ event: JellyfinSocket.Session.Event) {
        guard case let .message(.generalCommandMessage(message)) = event,
              message.data?.name == .displayMessage,
              let arguments = message.data?.arguments,
              let text = arguments["Text"],
              text.isNotEmpty
        else {
            return
        }

        Notifications[.didReceiveSessionMessage].post(
            .init(
                header: arguments["Header"],
                text: text,
                timeoutMs: arguments["TimeoutMs"].flatMap(Int.init)
            )
        )
    }
}
