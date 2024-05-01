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

enum UserSignInPolicy: Codable {

    case requireEveryTime
    case save(accessToken: String)
}

extension SwiftfinStore {

    struct UserSignInPolicyCoder: FieldCoderType {

        static func encodeToStoredData(_ fieldValue: UserSignInPolicy?) -> Data? {
            try? JSONEncoder().encode(fieldValue)
        }

        static func decodeFromStoredData(_ data: Data?) -> UserSignInPolicy? {
            guard let data else { return nil }
            return try? JSONDecoder().decode(UserSignInPolicy.self, from: data)
        }
    }
}
