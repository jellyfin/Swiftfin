//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Factory
import Foundation
import Get
import JellyfinAPI
import Pulse

final class ConnectToServerViewModel: ViewModel {

    @Published
    private(set) var discoveredServers: [ServerState] = []

    @Published
    private(set) var isSearching = false

    private let discovery = ServerDiscovery()

    var connectToServerTask: Task<ServerState, Error>?

    func connectToServer(url: String) async throws -> (server: ServerState, url: URL) {

        let formattedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)

        guard let url = URL(string: formattedURL) else { throw JellyfinAPIError("Invalid URL") }

        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: url),
            sessionDelegate: URLSessionProxyDelegate()
        )

        let response = try await client.send(Paths.getPublicSystemInfo)

        guard let name = response.value.serverName,
              let id = response.value.id,
              let os = response.value.operatingSystem,
              let version = response.value.version
        else {
            throw JellyfinAPIError("Missing server data from network call")
        }

        let newServerState = ServerState(
            urls: [url],
            currentURL: url,
            name: name,
            id: id,
            os: os,
            version: version,
            usersIDs: []
        )

        return (newServerState, url)
    }

    func isDuplicate(server: ServerState) -> Bool {
        if let _ = try? SwiftfinStore.dataStack.fetchOne(
            From<SwiftfinStore.Models.StoredServer>(),
            [Where<SwiftfinStore.Models.StoredServer>(
                "id == %@",
                server.id
            )]
        ) {
            return true
        }
        return false
    }

    func save(server: ServerState) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let newServer = transaction.create(Into<SwiftfinStore.Models.StoredServer>())

            newServer.urls = server.urls
            newServer.currentURL = server.currentURL
            newServer.name = server.name
            newServer.id = server.id
            newServer.os = server.os
            newServer.version = server.version
            newServer.users = []
        }
    }

    func discoverServers() {
        isSearching = true
        discoveredServers.removeAll()

        var _discoveredServers: Set<SwiftfinStore.State.Server> = []

        discovery.locateServer { server in
            if let server = server {
                _discoveredServers.insert(.init(
                    urls: [],
                    currentURL: server.url,
                    name: server.name,
                    id: server.id,
                    os: "",
                    version: "",
                    usersIDs: []
                ))
            }
        }

        // Timeout after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isSearching = false
            self.discoveredServers = _discoveredServers.sorted(by: { $0.name < $1.name })
        }
    }

    func add(url: URL, server: ServerState) {
        try! SwiftfinStore.dataStack.perform { transaction in
            let existingServer = try! SwiftfinStore.dataStack.fetchOne(
                From<SwiftfinStore.Models.StoredServer>(),
                [Where<SwiftfinStore.Models.StoredServer>(
                    "id == %@",
                    server.id
                )]
            )

            let editServer = transaction.edit(existingServer)!
            editServer.urls.insert(url)
        }
    }
}
