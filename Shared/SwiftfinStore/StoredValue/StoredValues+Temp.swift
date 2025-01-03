//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// Note: Temporary values to avoid refactoring or
//       reduce complexity at local sites.
//
//       Values can be cleaned up at any time and are
//       meant to have a short lifetime.

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

        static let userAccessPolicy: Key<UserAccessPolicy> = TempKey(
            "userSignInPolicy",
            ownerID: "temporary",
            domain: "userSignInPolicy",
            default: .none
        )

        static let userLocalPin: Key<String> = TempKey(
            "userLocalPin",
            ownerID: "temporary",
            domain: "userLocalPin",
            default: ""
        )

        static let userLocalPinHint: Key<String> = TempKey(
            "userLocalPinHint",
            ownerID: "temporary",
            domain: "userLocalPinHint",
            default: ""
        )

        static let userData: Key<UserDto> = TempKey(
            "tempUserData",
            ownerID: "temporary",
            domain: "tempUserData",
            default: .init()
        )
    }
}
