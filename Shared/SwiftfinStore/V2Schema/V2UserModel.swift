//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import UIKit

// TODO: complete and make migration

extension SwiftfinStore.V2 {

    final class StoredUser: CoreStoreObject {

        @Field.Coded("localAccessPolicy", coder: SwiftfinStore.UserLocalAccessPolicyCoder.self)
        var signInPolicy: UserLocalAccessPolicy?

        @Field.Stored("username")
        var username: String = ""

        @Field.Stored("id")
        var id: String = ""

        @Field.Stored("appleTVID")
        var appleTVID: String = ""

        @Field.Relationship("server")
        var server: StoredServer?

        var state: UserState {
            guard let server = server else { fatalError("No server associated with user") }
            return .init(
                accessToken: "",
                id: id,
                serverID: server.id,
                username: username
            )
        }
    }
}

// TODO: complete, cleanup

enum UserLocalAccessPolicy: Codable {

    case deviceAuth
    case noPassword
    case pin
}

extension SwiftfinStore {

    struct UserLocalAccessPolicyCoder: FieldCoderType {

        static func encodeToStoredData(_ fieldValue: UserLocalAccessPolicy?) -> Data? {
            try? JSONEncoder().encode(fieldValue)
        }

        static func decodeFromStoredData(_ data: Data?) -> UserLocalAccessPolicy? {
            guard let data else { return nil }
            return try? JSONDecoder().decode(UserLocalAccessPolicy.self, from: data)
        }
    }
}
