//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

// TODO: require remote sign in every time
//       - actually found to be a bit difficult?
// TODO: rename to not confuse with server access/UserDto

enum UserAccessPolicy: String, CaseIterable, Codable, Displayable {

    case none
    case requireDeviceAuthentication
    case requirePin

    var displayTitle: String {
        switch self {
        case .none:
            L10n.none
        case .requireDeviceAuthentication:
            "Device Authentication"
        case .requirePin:
            L10n.pin
        }
    }
}
