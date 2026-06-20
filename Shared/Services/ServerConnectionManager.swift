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
import Logging
import Network
import Pulse

@MainActor
@Stateful
final class ServerConnectionManager: ObservableObject {

    @CasePathable
    enum Action {
        case pathDidUpdate(NetworkConnectionContext)
        case resolveActiveConnection
        case scheduleConnectionResolution
        case start
        case stop

        case _resolutionDidUpdate(Resolution)

        var transition: Transition {
            switch self {
            case .pathDidUpdate, .scheduleConnectionResolution, .start:
                .none
            case .resolveActiveConnection:
                .to(.evaluating)
            case let ._resolutionDidUpdate(.offline(context)):
                .to(.offline(context))
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
        case offline(NetworkConnectionContext)
        case evaluating
        case connected(ServerConnection)
        case unreachable([ServerConnection])
    }

    enum Resolution: Equatable {
        case offline(NetworkConnectionContext)
        case connected(ServerConnection)
        case unreachable([ServerConnection])
    }

    private static let logger = Logger.swiftfin()

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
        let orderedCandidates = orderedConnectionCandidates(candidates, currentConnection: currentConnection)
        guard let reachableConnection = await firstReachableConnection(
            in: orderedCandidates,
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

    @Function(\Action.Cases.start)
    private func _start() {
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
                Task { @MainActor in
                    self?.scheduleConnectionResolution()
                }
            }
            .store(in: &cancellables)

        scheduleConnectionResolution()
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
        evaluationTask?.cancel()
        evaluationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            await self?.resolveActiveConnection()
        }
    }

    @Function(\Action.Cases.resolveActiveConnection)
    private func _resolveActiveConnection() async {
        guard !Task.isCancelled else { return }

        func apply(_ resolution: Resolution) async {
            await _resolutionDidUpdate(resolution)
        }

        let context = self.context

        guard context.isSatisfied else {
            guard !Task.isCancelled else { return }
            await apply(.offline(context))
            return
        }

        let candidates = userSession.server.serverConnections.filter { $0.matches(context) }
        guard candidates.isNotEmpty else {
            guard !Task.isCancelled else { return }
            await apply(.unreachable([]))
            return
        }

        let currentConnection = userSession.server.activeServerConnection
        let orderedCandidates = Self.orderedConnectionCandidates(candidates, currentConnection: currentConnection)

        let reachableConnection = await Self.firstReachableConnection(
            in: orderedCandidates,
            accessToken: userSession.user.accessToken,
            serverID: userSession.server.id
        )
        guard !Task.isCancelled else { return }

        guard let reachableConnection else {
            await apply(.unreachable(orderedCandidates))
            return
        }

        if currentConnection?.id != reachableConnection.id {
            userSession.server.activeServerConnection = reachableConnection
            Notifications.postServerConnectionChange(
                previous: currentConnection,
                current: reachableConnection
            )
        }

        guard !Task.isCancelled else { return }
        await apply(.connected(reachableConnection))
    }

    @Function(\Action.Cases._resolutionDidUpdate)
    private func _commitResolutionUpdate(_ resolution: Resolution) {
        _ = resolution
    }

    @Function(\Action.Cases.pathDidUpdate)
    private func _pathDidUpdate(_ context: NetworkConnectionContext) {
        self.context = context
        scheduleConnectionResolution()
    }

    private static func orderedConnectionCandidates(
        _ candidates: [ServerConnection],
        currentConnection: ServerConnection?
    ) -> [ServerConnection] {
        guard let currentConnection,
              let currentIndex = candidates.firstIndex(where: { $0.id == currentConnection.id })
        else {
            return candidates
        }

        var candidates = candidates
        let current = candidates.remove(at: currentIndex)
        return [current] + candidates
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
