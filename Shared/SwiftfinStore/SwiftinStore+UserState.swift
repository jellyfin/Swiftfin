//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import JellyfinAPI
import Pulse
import UIKit

extension SwiftfinStore.State {

    struct User: Hashable, Identifiable {

        let accessToken: String
        let id: String
        let serverID: String
        let username: String

        init(
            accessToken: String,
            id: String,
            serverID: String,
            username: String
        ) {
            self.accessToken = accessToken
            self.id = id
            self.serverID = serverID
            self.username = username
        }
    }
}

extension UserState {

    /// Deletes the model that this state represents and
    /// all settings from `Defaults` and `StoredValues`
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
    }

    /// Deletes user settings from `UserDefaults` and `StoredValues`
    ///
    /// Note: if performing deletion with another transaction, use
    ///       `AnyStoredData.fetchClause` instead within that transaction
    ///       and delete `UserDefaults` manually
    func deleteSettings() throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let userData = try transaction.fetchAll(
                From<AnyStoredData>()
                    .where(\.$ownerID == id)
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
            sessionDelegate: URLSessionProxyDelegate(logger: LogManager.pulseNetworkLogger()),
            accessToken: accessToken
        )

        let request = Paths.getCurrentUser
        let response = try await client.send(request)

        return response.value
    }

    func profileImageSource(
        client: JellyfinClient,
        maxWidth: CGFloat? = nil,
        maxHeight: CGFloat? = nil
    ) -> ImageSource {
        let scaleWidth = maxWidth == nil ? nil : UIScreen.main.scale(maxWidth!)
        let scaleHeight = maxHeight == nil ? nil : UIScreen.main.scale(maxHeight!)

        let parameters = Paths.GetUserImageParameters(maxWidth: scaleWidth, maxHeight: scaleHeight)
        let request = Paths.getUserImage(
            userID: id,
            imageType: "Primary",
            parameters: parameters
        )

        let profileImageURL = client.fullURL(with: request)

        return ImageSource(url: profileImageURL)
    }
}
