//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum SelectUserServerSelection: RawRepresentable, Hashable, Storable {

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

    func server(from servers: some Sequence<ServerState>) -> ServerState? {
        switch self {
        case .all:
            nil
        case let .server(id):
            servers.first { $0.id == id }
        }
    }
}
