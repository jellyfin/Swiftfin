//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import JellyfinAPI
import Pulse

extension SwiftfinStore.State {

    struct Server: Hashable, Identifiable, Codable {

        @available(*, message: "Use connections instead")
        let urls: Set<URL>
        @available(*, message: "Use connections instead")
        let currentURL: URL
        let name: String
        let id: String
        let userIDs: [String]

        /// - Note: Since this is created from a server, it does not
        ///         have a user access token.
        var client: JellyfinClient {
            JellyfinClient(
                configuration: .swiftfinConfiguration(url: effectiveServerURL),
                sessionConfiguration: .swiftfin,
                sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
            )
        }
    }
}

extension ServerState {

    var activeServerConnection: ServerConnection? {
        get {
            let connections = serverConnections
            let activeConnectionID = StoredValues[.Server.activeConnectionID(id: id)]

            if activeConnectionID.isNotEmpty,
               let connection = connections.first(where: { $0.id == activeConnectionID })
            {
                return connection
            }

            return connections.first { $0.url == currentURL } ?? connections.first
        }
        nonmutating set {
            StoredValues[.Server.activeConnectionID(id: id)] = newValue?.id ?? .empty
        }
    }

    /// Deletes the model that this state represents and
    /// all settings from `StoredValues`.
    func delete() throws {
        let users = StoredValues[.User.users]
            .filter { $0.serverID == id }

        for user in users {
            try AnyStoredData.deleteAll(ownerID: user.id)
        }
        try AnyStoredData.deleteAll(ownerID: id)

        var storedUsers = StoredValues[.User.users]
        storedUsers.removeAll { $0.serverID == id }
        StoredValues[.User.users] = storedUsers

        var servers = StoredValues[.Server.servers]
        servers.removeAll { $0.id == id }
        StoredValues[.Server.servers] = servers

        for user in users {
            UserDefaults.userSuite(id: user.id).removeAll()
        }
    }

    var effectiveServerURL: URL {
        activeServerConnection?.url ?? currentURL
    }

    func ensureServerConnections() -> [ServerConnection] {
        let connections = StoredValues[.Server.connections(id: id)]
        guard connections.isEmpty else { return ServerConnection.normalize(connections) }

        let defaultConnections = ServerConnection.defaults(for: self)
        serverConnections = defaultConnections
        return defaultConnections
    }

    func getPublicSystemInfo() async throws -> PublicSystemInfo {

        let request = Paths.getPublicSystemInfo
        let response = try await client.send(request)

        return response.value
    }

    func hasServerConnection(url: URL) -> Bool {
        let normalizedURL = url.normalizedServerConnectionURL ?? url
        return serverConnections.contains { $0.normalizedURL == normalizedURL }
    }

    var isAutoSwitchEnabled: Bool {
        get {
            StoredValues[.Server.isAutoSwitchEnabled(id: id)]
        }
        nonmutating set {
            StoredValues[.Server.isAutoSwitchEnabled(id: id)] = newValue
        }
    }

    var isVersionCompatible: Bool {
        let publicInfo = StoredValues[.Server.publicInfo(id: self.id)]

        if let version = publicInfo.version {
            return JellyfinClient.Version(stringLiteral: version).majorMinor >= client.version.majorMinor
        } else {
            return false
        }
    }

    var serverConnections: [ServerConnection] {
        get {
            let connections = StoredValues[.Server.connections(id: id)]

            guard connections.isNotEmpty else {
                return ServerConnection.defaults(for: self)
            }

            return ServerConnection.normalize(connections)
        }
        nonmutating set {
            StoredValues[.Server.connections(id: id)] = ServerConnection.normalize(newValue, preservingOrder: true)
        }
    }

    var splashScreenImageSource: ImageSource {
        ImageSource(url: client.url(with: Paths.getSplashscreen()))
    }

    @MainActor
    func updateServerInfo() async throws {
        let servers = StoredValues[.Server.servers]
        guard let currentServer = servers.first(where: { $0.id == id }) else { return }

        let publicInfo = try await getPublicSystemInfo()
        let updatedName = publicInfo.serverName ?? currentServer.name

        let updatedServer = ServerState(
            urls: currentServer.urls,
            currentURL: currentServer.currentURL,
            name: updatedName,
            id: currentServer.id,
            userIDs: currentServer.userIDs
        )

        StoredValues[.Server.servers] = servers.map { $0.id == id ? updatedServer : $0 }
        StoredValues[.Server.publicInfo(id: currentServer.id)] = publicInfo
    }
}
