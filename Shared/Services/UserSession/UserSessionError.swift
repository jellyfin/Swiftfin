//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum UserSessionError: Error {

    case missingCurrentSession

    var localizedDescription: String? {
        switch self {
        case .missingCurrentSession:
            "No signed-in user session is available."
        }
    }
}
