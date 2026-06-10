//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

extension StoredValues.Keys.Server {

    static func connections(id: String) -> StoredValues.Key<[ServerConnection]> {
        StoredValues.Keys.ServerKey(
            ownerID: id,
            field: "serverConnections",
            default: []
        )
    }

    static func activeConnectionID(id: String) -> StoredValues.Key<String> {
        StoredValues.Keys.ServerKey(
            ownerID: id,
            field: "activeServerConnectionID",
            default: String.empty
        )
    }

    static func isAutoSwitchingConnections(id: String) -> StoredValues.Key<Bool> {
        StoredValues.Keys.ServerKey(
            ownerID: id,
            field: "isAutoSwitchingServerConnections",
            default: false
        )
    }
}

enum ServerConnectionStore {

    static func connections(for server: ServerState) -> [ServerConnection] {
        let storedConnections = StoredValues[.Server.connections(id: server.id)]

        guard storedConnections.isNotEmpty else {
            return ServerConnection.defaults(for: server)
        }

        return normalize(storedConnections)
    }

    static func ensureConnections(for server: ServerState) -> [ServerConnection] {
        let storedConnections = StoredValues[.Server.connections(id: server.id)]
        guard storedConnections.isEmpty else { return normalize(storedConnections) }

        let defaultConnections = ServerConnection.defaults(for: server)
        save(defaultConnections, for: server.id)
        return defaultConnections
    }

    static func save(_ connections: [ServerConnection], for serverID: String) {
        StoredValues[.Server.connections(id: serverID)] = normalize(connections, preservingOrder: true)
    }

    static func activeConnection(for server: ServerState) -> ServerConnection? {
        let connections = connections(for: server)
        let activeConnectionID = StoredValues[.Server.activeConnectionID(id: server.id)]

        if activeConnectionID.isNotEmpty,
           let connection = connections.first(where: { $0.id == activeConnectionID })
        {
            return connection
        }

        return connections.first { $0.url == server.currentURL } ?? connections.first
    }

    static func setActiveConnection(_ connection: ServerConnection, for server: ServerState) {
        StoredValues[.Server.activeConnectionID(id: server.id)] = connection.id
    }

    static func effectiveURL(for server: ServerState) -> URL {
        activeConnection(for: server)?.url ?? server.currentURL
    }

    static func contains(_ url: URL, for server: ServerState) -> Bool {
        connections(for: server).contains { $0.url == url }
    }

    static func isAutoSwitchingEnabled(for serverID: String) -> Bool {
        StoredValues[.Server.isAutoSwitchingConnections(id: serverID)]
    }

    static func setAutoSwitchingEnabled(_ isEnabled: Bool, for serverID: String) {
        StoredValues[.Server.isAutoSwitchingConnections(id: serverID)] = isEnabled
    }

    static func normalize(_ connections: [ServerConnection], preservingOrder: Bool = false) -> [ServerConnection] {
        let connections = preservingOrder ? connections : connections.sorted(using: \.priority)

        return connections
            .enumerated()
            .map { index, connection in
                connection.with(priority: index)
            }
    }
}

extension ServerState {

    var serverConnections: [ServerConnection] {
        ServerConnectionStore.connections(for: self)
    }

    var activeServerConnection: ServerConnection? {
        ServerConnectionStore.activeConnection(for: self)
    }

    var effectiveServerURL: URL {
        ServerConnectionStore.effectiveURL(for: self)
    }

    func hasServerConnection(url: URL) -> Bool {
        ServerConnectionStore.contains(url, for: self)
    }
}
