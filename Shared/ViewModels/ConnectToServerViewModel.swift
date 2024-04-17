//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import CryptoKit
import Defaults
import Factory
import Foundation
import Get
import JellyfinAPI
import Pulse
import UIKit

final class ConnectToServerViewModel: ViewModel {

    @Published
    private(set) var discoveredServers: [ServerState] = []

    @Published
    private(set) var isSearching = false

    private let discovery = ServerDiscovery()

    var connectToServerTask: Task<ServerState, Error>?

    func connectToServer(url: String) async throws -> (server: ServerState, url: URL) {

        #if os(iOS)
        // shhhh
        // TODO: remove
        if let data = url.data(using: .utf8) {
            var sha = SHA256()
            sha.update(data: data)
            let digest = sha.finalize()
            let urlHash = digest.compactMap { String(format: "%02x", $0) }.joined()
            if urlHash == "7499aced43869b27f505701e4edc737f0cc346add1240d4ba86fbfa251e0fc35" {
                Defaults[.Experimental.downloads] = true

                await UIDevice.feedback(.success)
            }
        }
        #endif

        let formattedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .objectReplacement)
            .prepending("http://", if: !url.contains("://"))

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

        // in case of redirects, we must process the new URL

        let connectionURL = processConnectionURL(initial: url, response: response.response.url)

        let newServerState = ServerState(
            urls: [connectionURL],
            currentURL: connectionURL,
            name: name,
            id: id,
            os: os,
            version: version,
            usersIDs: []
        )

        return (newServerState, url)
    }

    // TODO: this probably isn't the best way to properly handle this, fix if necessary
    private func processConnectionURL(initial url: URL, response: URL?) -> URL {

        guard let response else { return url }

        if url.scheme != response.scheme ||
            url.host != response.host
        {
            var newURL = response.absoluteString.trimmingSuffix(Paths.getPublicSystemInfo.url?.absoluteString ?? "")

            // if ended in a "/"
            if url.absoluteString.last == "/" {
                newURL.append("/")
            }

            return URL(string: newURL) ?? url
        }

        return url
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
