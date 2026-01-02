//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum UserSignInState: RawRepresentable, Codable, Hashable, Storable {

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
