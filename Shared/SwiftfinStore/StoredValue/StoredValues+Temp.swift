//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension StoredValues.Keys {

    static func TempKey<Value: Codable>(
        _ name: String?,
        ownerID: String,
        domain: String,
        default defaultValue: Value
    ) -> Key<Value> {
        guard let name else {
            return Key(always: defaultValue)
        }

        return Key(
            name,
            ownerID: ownerID,
            domain: domain,
            default: defaultValue
        )
    }
}

// MARK: values

extension StoredValues.Keys {

    enum Temp {

        static let userData: Key<UserDto> = TempKey(
            "tempUserData",
            ownerID: "temporary",
            domain: "tempUserData",
            default: .init()
        )
    }
}
