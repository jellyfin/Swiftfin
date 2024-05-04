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

    func fetchAnyData<Value: Codable>(name: String) throws -> Value? {
        let values = try SwiftfinStore.dataStack
            .fetchAll(
                From<AnyStoredData>()
                    .where(\.$id == id && \.$name == name)
            )
            .compactMap(\.data)
            .compactMap {
                try JSONDecoder().decode(Value.self, from: $0)
            }

        assert(values.count < 2, "More than one stored object for same name and id?")

        return values.first
    }

    func storeAnyData<Value: Codable>(value: Value, name: String) throws {
        try SwiftfinStore.dataStack.perform { transaction in
            let existing = try transaction.fetchAll(
                From<AnyStoredData>()
                    .where(\.$id == id && \.$name == name)
            )

            assert(existing.count < 2, "More than one stored object for same name and id?")

            let encodedData = try JSONEncoder().encode(value)

            if let existingObject = existing.first {
                let edit = transaction.edit(existingObject)
                existingObject.data = encodedData
            } else {
                let newData = transaction.create(Into<AnyStoredData>())

                newData.data = encodedData
                newData.id = id
                newData.name = name
            }
        }
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
