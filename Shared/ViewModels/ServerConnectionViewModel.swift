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
import SwiftUI

@MainActor
final class ServerConnectionViewModel: ViewModel {

    @Published
    private(set) var server: ServerState
    @Published
    private(set) var connections: [ServerConnection]
    @Published
    private(set) var activeConnection: ServerConnection?
    @Published
    private(set) var isEvaluatingAutoSwitchConnection: Bool = false
    @Published
    var isAutoSwitchEnabled: Bool {
        didSet {
            guard oldValue != isAutoSwitchEnabled else { return }
            guard Defaults[.Experimental.serverConnectionAutoSwitch] else { return }

            server.isAutoSwitchEnabled = isAutoSwitchEnabled

            if isAutoSwitchEnabled {
                Container.shared.userSessionManager().scheduleServerConnectionEvaluation()
            }
        }
    }

    @Published
    private(set) var testStates: [String: ServerConnection.TestState] = [:]

    init(server: ServerState) {
        self.server = server
        self.connections = server.ensureServerConnections()
        self.activeConnection = server.activeServerConnection
        self.isAutoSwitchEnabled = server.isAutoSwitchEnabled
        super.init()

        Notifications[.didChangeServerConnection]
            .publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.reloadConnections()
            }
            .store(in: &cancellables)
    }

    func delete() {
        do {
            try server.delete()
            Notifications[.didDeleteServer].post(server)
        } catch {
            logger.critical("Unable to delete server: \(server.name)")
        }
    }

    func newConnection() -> ServerConnection {
        ServerConnection(
            name: "",
            url: server.effectiveServerURL,
            interface: .any,
            priority: connections.count
        )
    }

    private func upsertConnection(_ connection: ServerConnection) {
        let previous = activeConnection
        let isActiveConnection = activeConnection?.id == connection.id

        if let index = connections.firstIndex(where: { $0.id == connection.id }) {
            connections[index] = connection
        } else {
            connections.append(connection)
        }

        saveConnections()

        guard isActiveConnection,
              let activeConnection
        else { return }

        Notifications.postServerConnectionChange(
            previous: previous,
            current: activeConnection
        )
    }

    func deleteConnection(_ connection: ServerConnection) {
        guard connections.count > 1 else { return }
        guard activeConnection?.id != connection.id else { return }

        connections.removeAll { $0.id == connection.id }
        saveConnections()
    }

    func setActiveConnection(_ connection: ServerConnection) {
        let previous = activeConnection
        activeConnection = connection
        server.activeServerConnection = connection
        Notifications.postServerConnectionChange(
            previous: previous,
            current: connection
        )
    }

    func setActiveConnectionIfValid(_ connection: ServerConnection) async -> ServerConnection.TestState {
        let state = await testConnection(connection)
        guard case .success = state else { return state }

        setActiveConnection(connection)
        return state
    }

    func moveConnections(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        connections.move(fromOffsets: offsets, toOffset: destination)
        saveConnections()
    }

    func testConnection(_ connection: ServerConnection) async -> ServerConnection.TestState {
        testStates[connection.id] = .testing

        do {
            _ = try await ServerConnectionManager.test(
                connection: connection,
                accessToken: userSession?.user.accessToken,
                matchingServerID: server.id
            )
            let state = ServerConnection.TestState.success
            testStates[connection.id] = state
            return state
        } catch {
            let state = ServerConnection.TestState.failure(error.localizedDescription)
            testStates[connection.id] = state
            return state
        }
    }

    func evaluateAutoSwitchConnection() async {
        guard Defaults[.Experimental.serverConnectionAutoSwitch] else { return }
        guard isAutoSwitchEnabled else { return }
        guard !isEvaluatingAutoSwitchConnection else { return }

        isEvaluatingAutoSwitchConnection = true
        defer { isEvaluatingAutoSwitchConnection = false }

        guard !Container.shared.userSessionManager().hasActivePlayback else { return }

        await ServerConnectionManager.evaluate(
            server: server,
            accessToken: userSession?.user.accessToken,
            context: NetworkConnectionContext.current()
        )
        reloadConnections()
    }

    func saveConnection(_ connection: ServerConnection) async -> ServerConnection.TestState {
        if ServerConnection.isDuplicate(connection, in: connections) {
            let state = ServerConnection.TestState.failure(L10n.connectionAlreadyExists)
            testStates[connection.id] = state
            return state
        }

        let state = await testConnection(connection)
        guard case .success = state else { return state }

        upsertConnection(connection)

        return state
    }

    private func saveConnections() {
        server.serverConnections = connections
        connections = server.serverConnections
        activeConnection = server.activeServerConnection
    }

    private func reloadConnections() {
        connections = server.serverConnections
        activeConnection = server.activeServerConnection
        isAutoSwitchEnabled = server.isAutoSwitchEnabled
    }
}
