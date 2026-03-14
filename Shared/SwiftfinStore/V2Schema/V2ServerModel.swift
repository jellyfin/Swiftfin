//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Foundation

// TODO: complete and make migration

extension SwiftfinStore.V2 {

    final class StoredServer: CoreStoreObject {

        @Field.Coded("urls", coder: FieldCoders.Json.self)
        var urls: Set<URL> = []

        @Field.Stored("currentURL")
        var currentURL: URL = .init(string: "/")!

        @Field.Stored("name")
        var name: String = ""

        @Field.Stored("id")
        var id: String = ""

        @Field.Relationship("users", inverse: \StoredUser.$server)
        var users: Set<StoredUser>

        var state: ServerState {
            .init(
                urls: urls,
                currentURL: currentURL,
                name: name,
                id: id,
                usersIDs: users.map(\.id)
            )
        }
    }
}
