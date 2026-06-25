//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI
import Logging
import Network
import Pulse

@MainActor
@Stateful
final class ServerConnectionManager: ObservableObject {

    @CasePathable
    enum Action {
        case resolveActiveConnection
        case scheduleConnectionResolution
        case start
        case stop

        case _resolutionDidUpdate(Resolution)

        var transition: Transition {
            switch self {
            case .scheduleConnectionResolution, .start:
                .none
            case .resolveActiveConnection:
                .to(.evaluating)
            case let ._resolutionDidUpdate(.connected(connection)):
                .to(.connected(connection))
            case let ._resolutionDidUpdate(.unreachable(connections)):
                .to(.unreachable(connections))
            case .stop:
                .to(.initial)
            }
        }
    }

    enum State: Equatable {
        case initial
        case evaluating
        case connected(ServerConnection)
        case unreachable([ServerConnection])
    }

    enum Resolution: Equatable {
        case connected(ServerConnection)
        case unreachable([ServerConnection])
    }

    private static let logger = Logger.swiftfin()

    private let queue = DispatchQueue(label: "Swiftfin.ServerConnectionMonitor")

    private weak var userSession: UserSession?
    private var monitor: NWPathMonitor?
    private var isStarted = false
    private var context: NetworkConnectionContext = .unavailable
    private var evaluationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    static func test(
        connection: ServerConnection,
        accessToken: String? = nil,
        matchingServerID serverID: String
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

        if publicInfo.id != serverID {
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
        Notifications[.didChangeServerConnection].post(reachableConnection)

        return reachableConnection
    }

    private static func firstReachableConnection(
        in connections: [ServerConnection],
        accessToken: String?,
        serverID: String
    ) async -> ServerConnection? {
        for connection in connections {
            guard !Task.isCancelled else { return nil }

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

    @Function(\Action.Cases.start)
    private func _start() {
        guard !isStarted else { return }
        isStarted = true

        let monitor = NWPathMonitor()
        self.monitor = monitor

        monitor.pathUpdateHandler = { [weak self] path in
            Task { [weak self] in
                let newContext = await NetworkConnectionContext(path: path)
                await self?.pathDidUpdate(newContext)
            }
        }
        monitor.start(queue: queue)

        Notifications[.applicationWillEnterForeground]
            .publisher
            .sink { [weak self] in
                Task { @MainActor in
                    self?.scheduleConnectionResolution()
                }
            }
            .store(in: &cancellables)
    }

    @Function(\Action.Cases.stop)
    private func _stop() {
        guard isStarted else { return }

        isStarted = false
        evaluationTask?.cancel()
        evaluationTask = nil
        cancellables.removeAll()
        monitor?.cancel()
        monitor = nil
        context = .unavailable
    }

    @Function(\Action.Cases.scheduleConnectionResolution)
    private func _scheduleConnectionResolution() {
        guard isAutoSwitchEnabled else { return }

        evaluationTask?.cancel()
        evaluationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await self?.resolveActiveConnection()
        }
    }

    @Function(\Action.Cases.resolveActiveConnection)
    private func _resolveActiveConnection() async {
        guard !Task.isCancelled, isAutoSwitchEnabled, let userSession else { return }

        guard context.isSatisfied else {
            guard !Task.isCancelled else { return }
            await _resolutionDidUpdate(.unreachable([]))
            return
        }

        let candidates = userSession.server.serverConnections.filter { $0.matches(context) }

        guard candidates.isNotEmpty else {
            guard !Task.isCancelled else { return }
            await _resolutionDidUpdate(.unreachable([]))
            return
        }

        let currentConnection = userSession.server.activeServerConnection
        let reachableConnection = await Self.firstReachableConnection(
            in: candidates,
            accessToken: userSession.user.accessToken,
            serverID: userSession.server.id
        )

        guard !Task.isCancelled else { return }

        guard let reachableConnection else {
            await _resolutionDidUpdate(.unreachable(candidates))
            return
        }

        if currentConnection?.id != reachableConnection.id {
            userSession.server.activeServerConnection = reachableConnection
            Notifications[.didChangeServerConnection].post(reachableConnection)
        }

        guard !Task.isCancelled else { return }

        await _resolutionDidUpdate(.connected(reachableConnection))
    }

    @Function(\Action.Cases._resolutionDidUpdate)
    private func __resolutionDidUpdate(_ resolution: Resolution) {
        // no-op, just for state transition
    }

    private func pathDidUpdate(_ context: NetworkConnectionContext) {
        self.context = context
        scheduleConnectionResolution()
    }

    private var isAutoSwitchEnabled: Bool {
        guard let userSession else { return false }
        return Defaults[.Experimental.serverConnectionAutoSwitch] && userSession.server.isAutoSwitchEnabled
    }
}

extension ServerConnectionManager: UserSessionService {

    func willStart(userSession: UserSession) async {
        self.userSession = userSession

        guard isAutoSwitchEnabled else { return }

        context = await NetworkConnectionContext.current()
        await resolveActiveConnection()
    }

    func didStart(userSession: UserSession) {
        start()
    }

    func willStop(userSession: UserSession) {
        stop()
    }
}
