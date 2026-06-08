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
import SwiftUI

enum ServerConnectionTestState: Equatable {
    case idle
    case testing
    case success(String)
    case failure(String)
}

@MainActor
final class ServerConnectionViewModel: ViewModel {

    @Published
    private(set) var server: ServerState
    @Published
    private(set) var connections: [ServerConnection]
    @Published
    private(set) var activeConnection: ServerConnection?
    @Published
    var isAutoSwitchingEnabled: Bool {
        didSet {
            ServerConnectionStore.setAutoSwitchingEnabled(isAutoSwitchingEnabled, for: server.id)

            if isAutoSwitchingEnabled {
                Container.shared.serverConnectionManager().scheduleEvaluation(reason: .automatic)
            }
        }
    }

    @Published
    private(set) var testStates: [String: ServerConnectionTestState] = [:]

    init(server: ServerState) {
        self.server = server
        self.connections = ServerConnectionStore.ensureConnections(for: server)
        self.activeConnection = ServerConnectionStore.activeConnection(for: server)
        self.isAutoSwitchingEnabled = ServerConnectionStore.isAutoSwitchingEnabled(for: server.id)
        super.init()

        Notifications[.didChangeServerConnection]
            .publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] change in
                guard change.server.id == self?.server.id else { return }
                self?.reloadConnections()
            }
            .store(in: &cancellables)
    }

    // TODO: this could probably be cleaner
    func delete() {
        let userStates = StoredValues[.User.users]
            .filter { $0.serverID == server.id }

        // Note: don't use Server/UserState.delete() to have
        //       all deletions in a single transaction
        do {
            for user in userStates {
                try AnyStoredData.deleteAll(ownerID: user.id)
            }
            try AnyStoredData.deleteAll(ownerID: self.server.id)

            var users = StoredValues[.User.users]
            users.removeAll { $0.serverID == self.server.id }
            StoredValues[.User.users] = users

            var servers = StoredValues[.Server.servers]
            servers.removeAll { $0.id == server.id }
            StoredValues[.Server.servers] = servers

            for user in userStates {
                UserDefaults.userSuite(id: user.id).removeAll()
            }

            Notifications[.didDeleteServer].post(server)
        } catch {
            logger.critical("Unable to delete server: \(server.name)")
        }
    }

    func newConnection() -> ServerConnection {
        ServerConnection(
            name: L10n.newConnection,
            url: server.effectiveServerURL,
            interface: .any,
            priority: connections.count
        )
    }

    private func addConnection(_ connection: ServerConnection) {
        connections.append(connection)
        saveConnections()
    }

    private func updateConnection(_ connection: ServerConnection) {
        guard let index = connections.firstIndex(where: { $0.id == connection.id }) else { return }

        let previous = activeConnection
        let isActiveConnection = activeConnection?.id == connection.id
        var updatedConnection = connection

        if !updatedConnection.isEnabled,
           !connections.contains(where: { $0.id != updatedConnection.id && $0.isEnabled })
        {
            updatedConnection.isEnabled = true
        }

        connections[index] = updatedConnection
        saveConnections()

        if isActiveConnection {
            let nextActiveConnection = if updatedConnection.isEnabled {
                connections.first { $0.id == updatedConnection.id }
            } else {
                connections.first(where: \.isEnabled)
            }

            guard let nextActiveConnection else { return }

            activeConnection = nextActiveConnection
            ServerConnectionStore.setActiveConnection(nextActiveConnection, for: server)
            postConnectionChange(
                previous: previous,
                current: nextActiveConnection,
                reason: updatedConnection.isEnabled ? .manual : .deletedActiveConnection
            )
        }
    }

    func deleteConnection(_ connection: ServerConnection) {
        guard connections.count > 1 else { return }
        guard activeConnection?.id != connection.id else { return }

        connections.removeAll { $0.id == connection.id }
        saveConnections()
        activeConnection = ServerConnectionStore.activeConnection(for: server)
    }

    func setActiveConnection(_ connection: ServerConnection) {
        guard connection.isEnabled else { return }

        let previous = activeConnection
        activeConnection = connection
        ServerConnectionStore.setActiveConnection(connection, for: server)
        postConnectionChange(previous: previous, current: connection, reason: .manual)
    }

    func setActiveConnectionIfValid(_ connection: ServerConnection) async -> ServerConnectionTestState {
        let state = await testConnection(connection)
        guard case .success = state else { return state }

        setActiveConnection(connection)
        return state
    }

    func moveConnections(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        connections.move(fromOffsets: offsets, toOffset: destination)
        saveConnections()
    }

    func testConnection(_ connection: ServerConnection) async -> ServerConnectionTestState {
        testStates[connection.id] = .testing

        do {
            let publicInfo = try await Container.shared.serverConnectionManager().test(
                connection: connection,
                accessToken: userSession?.user.accessToken,
                matchingServerID: server.id
            )
            let version = publicInfo.version ?? "unknown version"
            let state = ServerConnectionTestState.success(version)
            testStates[connection.id] = state
            return state
        } catch {
            let state = ServerConnectionTestState.failure(error.localizedDescription)
            testStates[connection.id] = state
            return state
        }
    }

    func saveConnection(_ connection: ServerConnection) async -> ServerConnectionTestState {
        let state = await testConnection(connection)
        guard case .success = state else { return state }

        if connections.contains(where: { $0.id == connection.id }) {
            updateConnection(connection)
        } else {
            addConnection(connection)
        }

        return state
    }

    private func saveConnections() {
        connections = ServerConnectionStore.normalize(connections)
        ServerConnectionStore.save(connections, for: server.id)

        if let activeConnection {
            self.activeConnection = connections.first { $0.id == activeConnection.id }
        }
    }

    private func reloadConnections() {
        connections = ServerConnectionStore.connections(for: server)
        activeConnection = ServerConnectionStore.activeConnection(for: server)
        isAutoSwitchingEnabled = ServerConnectionStore.isAutoSwitchingEnabled(for: server.id)
    }

    private func postConnectionChange(
        previous: ServerConnection?,
        current: ServerConnection,
        reason: ServerConnectionChange.Reason
    ) {
        guard previous?.id != current.id || previous?.url != current.url else { return }

        Notifications[.didChangeServerConnection].post(
            .init(
                server: server,
                previous: previous,
                current: current,
                reason: reason
            )
        )
    }
}
