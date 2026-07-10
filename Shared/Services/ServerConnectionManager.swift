//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import Logging
import Network
import Pulse

final class ServerConnectionManager {

    private static let logger = Logger.swiftfin()

    private let logger = Logger.swiftfin()
    private let queue = DispatchQueue(label: "Swiftfin.ServerConnectionMonitor")

    private var userSession: UserSession
    private var monitor: NWPathMonitor?
    private var isStarted = false
    private var context: NetworkConnectionContext = .unavailable
    private var evaluationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(userSession: UserSession) {
        self.userSession = userSession
    }

    static func test(
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
            throw ErrorMessage(L10n.connectionServerMismatch)
        }

        return publicInfo
    }

    @MainActor
    static func evaluate(
        server: ServerState,
        accessToken: String?,
        context: NetworkConnectionContext
    ) async -> ServerConnection? {
        guard context.isSatisfied else { return nil }

        let candidates = server.serverConnections.filter { $0.matches(context) }

        let currentConnection = server.activeServerConnection
        guard let reachableConnection = await firstReachableConnection(
            in: candidates,
            accessToken: accessToken,
            serverID: server.id
        ) else { return nil }
        guard currentConnection?.id != reachableConnection.id else { return nil }

        server.activeServerConnection = reachableConnection
        Notifications.postServerConnectionChange(
            previous: currentConnection,
            current: reachableConnection
        )

        return reachableConnection
    }

    private static func firstReachableConnection(
        in connections: [ServerConnection],
        accessToken: String?,
        serverID: String
    ) async -> ServerConnection? {
        for connection in connections {
            if Task.isCancelled {
                return nil
            }

            do {
                _ = try await test(
                    connection: connection,
                    accessToken: accessToken,
                    matchingServerID: serverID
                )
                return connection
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

        return nil
    }

    @MainActor
    func update(userSession: UserSession) {
        self.userSession = userSession
    }

    @MainActor
    func start() {
        guard !isStarted else { return }
        isStarted = true

        let monitor = NWPathMonitor()
        self.monitor = monitor

        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                let context = await NetworkConnectionContext.current(path: path)
                await self?.pathDidUpdate(context)
            }
        }
        monitor.start(queue: queue)

        Notifications[.applicationWillEnterForeground]
            .publisher
            .sink { [weak self] in
                self?.scheduleEvaluation()
            }
            .store(in: &cancellables)

        scheduleEvaluation()
    }

    @MainActor
    func stop() {
        guard isStarted else { return }

        isStarted = false
        evaluationTask?.cancel()
        evaluationTask = nil
        cancellables.removeAll()
        monitor?.cancel()
        monitor = nil
        context = .unavailable
    }

    @MainActor
    func scheduleEvaluation() {
        guard Defaults[.Experimental.serverConnectionAutoSwitch] else { return }

        evaluationTask?.cancel()
        evaluationTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await self?.evaluateCurrentSession()
        }
    }

    @MainActor
    func evaluateCurrentSession() async {
        await evaluate(
            server: userSession.server,
            accessToken: userSession.user.accessToken
        )
    }

    @MainActor
    func evaluate(
        server: ServerState,
        accessToken: String?
    ) async {
        guard Defaults[.Experimental.serverConnectionAutoSwitch] else { return }
        guard server.isAutoSwitchEnabled else { return }

        guard !Container.shared.userSessionManager().hasActivePlayback else {
            logger.info("Skipped server connection switch during active playback")
            return
        }

        _ = await Self.evaluate(
            server: server,
            accessToken: accessToken,
            context: context
        )
    }

    @MainActor
    private func pathDidUpdate(_ context: NetworkConnectionContext) {
        self.context = context
        scheduleEvaluation()
    }
}

extension ServerConnectionManager: UserSessionService {

    @MainActor
    func userSessionDidStart() {
        start()
    }

    @MainActor
    func userSessionWillStop() {
        stop()
    }
}
