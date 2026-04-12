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
import KeychainSwift
import Pulse
import UIKit

// Note: it is kind of backwards to have a "state" object with a mix of
//       non-mutable and "mutable" values, but it just works.

extension SwiftfinStore.State {

    struct User: Hashable, Identifiable, Codable {

        let id: String
        let serverID: String
        let username: String

        init(
            id: String,
            serverID: String,
            username: String
        ) {
            self.id = id
            self.serverID = serverID
            self.username = username
        }
    }
}

extension UserState {

    typealias Key = StoredValues.Key

    var accessToken: String {
        get {
            guard let accessToken = Container.shared.keychainService().get("\(id)-accessToken") else {
                assertionFailure("access token missing in keychain")
                return ""
            }

            return accessToken
        }
        nonmutating set {
            Container.shared.keychainService().set(newValue, forKey: "\(id)-accessToken")
        }
    }

    var data: UserDto {
        get {
            StoredValues[.User.data(id: id)]
        }
        nonmutating set {
            StoredValues[.User.data(id: id)] = newValue
        }
    }

    var pin: String {
        get {
            guard let pin = Container.shared.keychainService().get("\(id)-pin") else {
                assertionFailure("pin missing in keychain")
                return ""
            }

            return pin
        }
        nonmutating set {
            Container.shared.keychainService().set(newValue, forKey: "\(id)-pin")
        }
    }

    var pinHint: String {
        get {
            StoredValues[.User.pinHint(id: id)]
        }
        nonmutating set {
            StoredValues[.User.pinHint(id: id)] = newValue
        }
    }

    var accessPolicy: UserAccessPolicy {
        get {
            StoredValues[.User.accessPolicy(id: id)]
        }
        nonmutating set {
            StoredValues[.User.accessPolicy(id: id)] = newValue
        }
    }
}

extension UserState {

    /// Deletes the model that this state represents and
    /// all settings from `Defaults` `Keychain`, and `StoredValues`
    func delete() throws {
        var users = StoredValues[.User.users]
        users.removeAll { $0.id == id }
        StoredValues[.User.users] = users

        try AnyStoredData.deleteAll(ownerID: id)

        var servers = StoredValues[.Server.servers]
        if let index = servers.firstIndex(where: { $0.id == serverID }) {
            let currentServer = servers[index]

            servers[index] = ServerState(
                urls: currentServer.urls,
                currentURL: currentServer.currentURL,
                name: currentServer.name,
                id: currentServer.id,
                usersIDs: currentServer.userIDs.filter { $0 != id }
            )

            StoredValues[.Server.servers] = servers
        }

        UserDefaults.userSuite(id: id).removeAll()

        let keychain = Container.shared.keychainService()
        keychain.delete("\(id)-pin")
    }

    /// Deletes user settings from `UserDefaults` and `StoredValues`
    ///
    /// Note: if performing deletion with another transaction, use
    ///       `AnyStoredData.fetchClause` instead within that transaction
    ///       and delete `Defaults` manually
    func deleteSettings() throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let userData = try transaction.fetchAll(
                From<AnyStoredData>()
                    .where(combineByAnd: Where(\.$ownerID == id), Where("%K BEGINSWITH %@", "domain", "setting"))
            )

            transaction.delete(userData)
        }

        UserDefaults.userSuite(id: id).removeAll()
    }

    /// Must pass the server to create a JellyfinClient
    /// with an access token
    func getUserData(server: ServerState) async throws -> UserDto {
        let client = JellyfinClient(
            configuration: .swiftfinConfiguration(url: server.currentURL, accessToken: accessToken),
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin())
        )

        let request = Paths.getCurrentUser
        let response = try await client.send(request)

        return response.value
    }

    // we will always crop to a square, so just use width
    func profileImageSource(
        client: JellyfinClient
    ) -> ImageSource {
        let parameters = Paths.GetUserImageParameters(
            userID: id
        )
        let request = Paths.getUserImage(parameters: parameters)

        let profileImageURL = client.fullURL(with: request)

        return ImageSource(url: profileImageURL)
    }
}
