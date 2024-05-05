//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI

// MARK: key/domain

extension StoredValues.Keys {

    // Domains for server data
    enum ServerDomain: String {

        /// Domain for main values of servers
        case main
    }

    // MARK: keys

    static func ServerKey<Value: Codable>(always: Value) -> Key<Value> {
        Key(always: always)
    }

    static func ServerKey<Value: Codable>(
        _ name: String?,
        domain: ServerDomain,
        default defaultValue: Value
    ) -> Key<Value> {
        guard let name, let currentServer = Container.userSession()?.server else {
            return Key(always: defaultValue)
        }

        return Key(
            name,
            ownerID: currentServer.id,
            domain: domain.rawValue,
            default: defaultValue
        )
    }
}

extension StoredValues.Keys {

    enum Server {

        static let info: Key<SystemInfo> = ServerKey(
            "info",
            domain: .main,
            default: .init()
        )

        static let publicInfo: Key<PublicSystemInfo> = ServerKey(
            "publicInfo",
            domain: .main,
            default: .init()
        )
    }
}
