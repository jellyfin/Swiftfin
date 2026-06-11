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
import Network
import Pulse

enum ServerConnectionValidationError: Error {
    case mismatchedServer

    var localizedDescription: String? {
        switch self {
        case .mismatchedServer:
            L10n.connectionServerMismatch
        }
    }
}

@MainActor
final class ServerConnectionManager {

    private let logger = Logger.swiftfin()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "Swiftfin.ServerConnectionMonitor")

    private var isStarted = false
    private var context: NetworkConnectionContext = .unavailable
    private var evaluationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    nonisolated init() {}

    func start() {
        guard !isStarted else { return }
        isStarted = true

        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                let context = await NetworkConnectionContext.current(path: path)
                await self?.pathDidUpdate(context)
            }
        }
        monitor.start(queue: queue)

        Notifications[.didSignIn]
            .publisher
            .sink { [weak self] in
                self?.scheduleEvaluation(reason: .automatic)
            }
            .store(in: &cancellables)

        Notifications[.applicationWillEnterForeground]
            .publisher
            .sink { [weak self] in
                self?.scheduleEvaluation(reason: .automatic)
            }
            .store(in: &cancellables)
    }

    func scheduleEvaluation(reason: ServerConnectionChange.Reason) {
        evaluationTask?.cancel()
        let nextTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await self?.evaluateCurrentSession(reason: reason)
        }

        evaluationTask = nextTask
    }

    func evaluateCurrentSession(reason: ServerConnectionChange.Reason) async {
        guard let session = Container.shared.userSessionManager().currentSession else { return }

        await evaluate(
            server: session.server,
            accessToken: session.user.accessToken,
            reason: reason
        )
    }

    func evaluate(
        server: ServerState,
        accessToken: String?,
        reason: ServerConnectionChange.Reason
    ) async {
        guard ServerConnectionStore.isAutoSwitchingEnabled(for: server.id) else { return }

        guard !Container.shared.userSessionManager().hasActivePlayback else {
            logger.info("Skipped server connection switch during active playback")
            return
        }

        let currentContext = context
        guard currentContext.isSatisfied else { return }

        let connections = ServerConnectionStore.connections(for: server)
        let candidates = connections.filter { $0.matches(currentContext) }
        guard candidates.isNotEmpty else { return }

        let currentConnection = ServerConnectionStore.activeConnection(for: server)

        for connection in candidates {
            if Task.isCancelled { return }

            do {
                _ = try await test(
                    connection: connection,
                    accessToken: accessToken,
                    matchingServerID: server.id
                )
                guard currentConnection?.id != connection.id else { return }

                ServerConnectionStore.setActiveConnection(connection, for: server)

                let change = ServerConnectionChange(
                    server: server,
                    previous: currentConnection,
                    current: connection,
                    reason: reason
                )

                Notifications[.didChangeServerConnection].post(change)
                return
            } catch {
                logger.info(
                    "Server connection probe failed",
                    metadata: [
                        "url": .string(connection.url.absoluteString),
                        "error": .string(error.localizedDescription),
                    ]
                )
            }
        }
    }

    func test(
        connection: ServerConnection,
        accessToken: String? = nil,
        matchingServerID serverID: String? = nil
    ) async throws -> PublicSystemInfo {
        let sessionConfiguration = URLSessionConfiguration.swiftfin.copy() as! URLSessionConfiguration
        sessionConfiguration.timeoutIntervalForRequest = 8
        sessionConfiguration.timeoutIntervalForResource = 12
        sessionConfiguration.waitsForConnectivity = false

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(
                url: connection.url,
                accessToken: accessToken
            ),
            sessionConfiguration: sessionConfiguration,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        let response = try await client.send(Paths.getPublicSystemInfo)
        let publicInfo = response.value

        if let serverID, publicInfo.id != serverID {
            throw ServerConnectionValidationError.mismatchedServer
        }

        return publicInfo
    }

    private func pathDidUpdate(_ context: NetworkConnectionContext) {
        self.context = context
        scheduleEvaluation(reason: .automatic)
    }
}

extension Container {

    var serverConnectionManager: Factory<ServerConnectionManager> {
        self { ServerConnectionManager() }
            .singleton
    }
}
