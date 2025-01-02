//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation
import UIKit

// TODO: complete and make migration

extension SwiftfinStore.V2 {

    final class StoredUser: CoreStoreObject {

        @Field.Stored("username")
        var username: String = ""

        @Field.Stored("id")
        var id: String = ""

        @Field.Relationship("server")
        var server: StoredServer?

        var state: UserState {
            guard let server = server else { fatalError("No server associated with user") }
            return .init(
                id: id,
                serverID: server.id,
                username: username
            )
        }
    }
}
