//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum UserSignInState: RawRepresentable, Codable, Defaults.Serializable, Equatable, Hashable {

    case signedOut
    case signedIn(userID: String)

    var rawValue: String {
        switch self {
        case .signedOut:
            ""
        case let .signedIn(userID):
            userID
        }
    }

    init?(rawValue: String) {
        if rawValue.isEmpty {
            self = .signedOut
        } else {
            self = .signedIn(userID: rawValue)
        }
    }
}
