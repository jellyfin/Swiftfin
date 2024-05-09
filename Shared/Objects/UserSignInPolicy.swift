//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation

enum UserSignInPolicy: String, CaseIterable, Codable, Displayable {

    case doNotSave
    case requireDeviceAuthentication
    case requirePin
    case save

    var displayTitle: String {
        switch self {
        case .doNotSave:
            "Do Not Save"
        case .requireDeviceAuthentication:
            "Device Authentication"
        case .requirePin:
            "Pin"
        case .save:
            "Save"
        }
    }
}
