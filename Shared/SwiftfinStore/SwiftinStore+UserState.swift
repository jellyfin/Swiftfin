//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import UIKit

extension SwiftfinStore.State {

    struct User: Hashable, Identifiable {

        let accessToken: String
        let id: String
        let serverID: String
        let username: String

        init(
            id: String,
            serverID: String,
            username: String
        ) {
            self.accessToken = "REPLACE ME"
            self.id = id
            self.serverID = serverID
            self.username = username
        }

        @available(*, deprecated, message: "Don't use sample states")
        static var sample: Self {
            .init(
                id: "123abc",
                serverID: "123abc",
                username: "JohnnyAppleseed"
            )
        }
    }
}
