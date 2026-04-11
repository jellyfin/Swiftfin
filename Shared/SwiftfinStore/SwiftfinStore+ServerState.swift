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

    struct Server: Hashable, Identifiable {

        let urls: Set<URL>
        let currentURL: URL
        let name: String
        let id: String
        let userIDs: [String]

        init(
            urls: Set<URL>,
            currentURL: URL,
            name: String,
            id: String,
            usersIDs: [String]
        ) {
            self.urls = urls
            self.currentURL = currentURL
            self.name = name
            self.id = id
            self.userIDs = usersIDs
        }

        /// - Note: Since this is created from a server, it does not
        ///         have a user access token.
        var client: JellyfinClient {
            JellyfinClient(
                configuration: .swiftfinConfiguration(url: currentURL),
                sessionConfiguration: .swiftfin,
                sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
            )
        }
    }
}

extension ServerState {

    /// Deletes the model that this state represents and
    /// all settings from `StoredValues`.
    func delete() throws {
        try SwiftfinStore.dataStack.perform { transaction in
            guard let storedServer = try transaction.fetchOne(From<ServerModel>().where(\.$id == id)) else {
                throw ErrorMessage("Unable to find server to delete")
            }

            let storedDataClause = AnyStoredData.fetchClause(ownerID: id)
            let storedData = try transaction.fetchAll(storedDataClause)

            transaction.delete(storedData)
            transaction.delete(storedServer)
        }
    }

    func getPublicSystemInfo() async throws -> PublicSystemInfo {

        let request = Paths.getPublicSystemInfo
        let response = try await client.send(request)

        return response.value
    }

    var splashScreenImageSource: ImageSource {
        let request = Paths.getSplashscreen()
        return ImageSource(url: client.fullURL(with: request))
    }

    @MainActor
    func updateServerInfo() async throws {
        guard let server = try? SwiftfinStore.dataStack.fetchOne(
            From<ServerModel>().where(Where(\.$id == id))
        ) else { return }

        let publicInfo = try await getPublicSystemInfo()

        try SwiftfinStore.dataStack.perform { transaction in
            guard let newServer = transaction.edit(server) else { return }

            newServer.name = publicInfo.serverName ?? newServer.name
            newServer.id = publicInfo.id ?? newServer.id
        }

        StoredValues[.Server.publicInfo(id: server.id)] = publicInfo
    }

    var isVersionCompatible: Bool {
        let publicInfo = StoredValues[.Server.publicInfo(id: self.id)]

        if let version = publicInfo.version {
            return JellyfinClient.Version(stringLiteral: version).majorMinor >= JellyfinClient.sdkVersion.majorMinor
        } else {
            return false
        }
    }
}
