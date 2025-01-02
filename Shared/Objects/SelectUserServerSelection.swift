//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation

enum SelectUserServerSelection: RawRepresentable, Codable, Defaults.Serializable, Equatable, Hashable {

    case all
    case server(id: String)

    var rawValue: String {
        switch self {
        case .all:
            "swiftfin-all"
        case let .server(id):
            id
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "swiftfin-all":
            self = .all
        default:
            self = .server(id: rawValue)
        }
    }
}
