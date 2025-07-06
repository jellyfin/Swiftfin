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
import Foundation
import JellyfinAPI
import KeychainSwift
import Pulse
import UIKit

// Note: it is kind of backwards to have a "state" object with a mix of
//       non-mutable and "mutable" values, but it just works.

extension SwiftfinStore.State {

    struct User: Hashable, Identifiable {

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

    var permissions: UserPermissions {
        UserPermissions(data.policy)
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
        try SwiftfinStore.dataStack.perform { transaction in
            guard let storedUser = try transaction.fetchOne(From<UserModel>().where(\.$id == id)) else {
                throw JellyfinAPIError("Unable to find user to delete")
            }

            let storedDataClause = AnyStoredData.fetchClause(ownerID: id)
            let storedData = try transaction.fetchAll(storedDataClause)

            transaction.delete(storedUser)
            transaction.delete(storedData)
        }

        UserDefaults.userSuite(id: id).removeAll()

        let keychain = Container.shared.keychainService()
        keychain.delete("\(id)-pin")

        // Clear default user setting if this user was set as the default
        if case let .signedIn(defaultUserID) = Defaults[.defaultUserID], defaultUserID == id {
            Defaults[.defaultUserID] = .signedOut
        }
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
            configuration: .swiftfinConfiguration(url: server.currentURL),
            sessionConfiguration: .swiftfin,
            sessionDelegate: URLSessionProxyDelegate(logger: NetworkLogger.swiftfin()),
            accessToken: accessToken
        )

        let request = Paths.getCurrentUser
        let response = try await client.send(request)

        return response.value
    }

    // we will always crop to a square, so just use width
    func profileImageSource(
        client: JellyfinClient,
        maxWidth: CGFloat? = nil
    ) -> ImageSource {
        let scaleWidth = maxWidth == nil ? nil : UIScreen.main.scale(maxWidth!)

        let parameters = Paths.GetUserImageParameters(
            userID: id,
            maxWidth: scaleWidth
        )
        let request = Paths.getUserImage(parameters: parameters)

        let profileImageURL = client.fullURL(with: request)

        return ImageSource(url: profileImageURL)
    }
}
