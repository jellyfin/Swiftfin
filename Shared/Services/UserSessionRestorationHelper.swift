//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Factory
import JellyfinAPI
import Logging
import Pulse

struct UserSessionRestorationHelper {
    private let logger = Logger.swiftfin()

    func getCurrentUserSession() -> UserSession? {
        guard case .signedIn(let userId) = Defaults[.lastSignedInUserID] else { return nil }

        guard let user = try? SwiftfinStore.dataStack.fetchOne(
            From<UserModel>().where(\.$id == userId)
        ) else {
            // had last user ID but no saved user
            Defaults[.lastSignedInUserID] = .signedOut

            return nil
        }

        guard let server = user.server,
              let _ = SwiftfinStore.dataStack.fetchExisting(server)
        else {
            fatalError("No associated server for last user")
        }

        return .init(
            server: server.state,
            user: user.state
        )
    }

    @MainActor
    func getInitialUserSession() async -> UserSession? {
        // Normal restore path
        if let userSession = getCurrentUserSession() {
            Defaults[.isFirstLaunch] = false
            return userSession
        }

        let keychain = Container.shared.keychainService()
        if Defaults[.isFirstLaunch] {
            keychain.clear()
            Defaults[.isFirstLaunch] = false
            return nil
        }


        // No user found in database, try to restore from keychain
        for key in keychain.allKeys where key.hasSuffix("-accessToken") {
            guard let accessTokenData = keychain.getData(key),
                  let accessToken = AccessToken(keychainData: accessTokenData)
            else {
                return nil
            }

            await restoreUserSessionWith(accessToken: accessToken)
        }

        // Try to get the user session again after attempting restoration
        return getCurrentUserSession()
    }

    @MainActor
    private func restoreUserSessionWith(accessToken: AccessToken) async {
        for serverURL in accessToken.associatedServerURLs {
            do {
                let client = JellyfinClient(
                    configuration: .swiftfinConfiguration(url: serverURL),
                    sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
                )

                let response = try await client.send(Paths.getPublicSystemInfo)

                guard let name = response.value.serverName,
                      let id = response.value.id
                else {
                    continue
                }

                let serverModel = try getOrCreateServer(
                    id: id,
                    name: name,
                    currentURL: serverURL,
                    urls: accessToken.associatedServerURLs
                )

                try saveUser(id: accessToken.userId, username: accessToken.username, serverModel: serverModel)

                return
            } catch {
                logger.error("Failed to restore user session for server URL \(serverURL): \(error.localizedDescription)")
            }
        }
    }

    private func getOrCreateServer(id: String, name: String, currentURL: URL, urls: Set<URL>) throws -> ServerModel {
        if let serverModel = try? Container.shared.dataStore().fetchOne(From<ServerModel>().where(\.$id == id)) {
            try Container.shared.dataStore().perform { transaction in
                let editServer = transaction.edit(serverModel)!
                editServer.urls.formUnion(urls)
            }

            return serverModel
        }

        return try Container.shared.dataStore().perform { transaction in
            let newServer = transaction.create(Into<ServerModel>())

            newServer.urls = urls
            newServer.currentURL = currentURL
            newServer.name = name
            newServer.id = id
            newServer.users = []

            return newServer
        }
    }

    private func saveUser(id: String, username: String, serverModel: ServerModel) throws {
        try Container.shared.dataStore().perform { transaction in
            let newUser = transaction.create(Into<UserModel>())

            newUser.id = id
            newUser.username = username

            let editServer = transaction.edit(serverModel)!
            editServer.users.insert(newUser)
        }
    }
}
