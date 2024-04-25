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

extension SwiftfinStore.V2 {

    final class StoredUser: CoreStoreObject {

        @Field.Stored("accessToken")
        var accessToken: String = ""

        @Field.Stored("username")
        var username: String = ""

        @Field.Stored("id")
        var id: String = ""

        @Field.Stored("appleTVID")
        var appleTVID: String = ""

        @Field.Relationship("server")
        var server: StoredServer?

        @Field.Coded("image", coder: SwiftfinStore.ImageCoder.self)
        var image: UIImage?

        var state: UserState {
            guard let server = server else { fatalError("No server associated with user") }
            return .init(
                accessToken: accessToken,
                id: id,
                serverID: server.id,
                username: username,
                image: image
            )
        }
    }
}
