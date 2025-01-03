//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

extension ServerDiscovery {

    struct ServerResponse: Codable, Hashable, Identifiable {

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        private let address: String
        let id: String
        let name: String

        var url: URL {
            URL(string: address)!
        }

        var host: String {
            let components = URLComponents(string: address)
            if let host = components?.host {
                return host
            }
            return self.address
        }

        var port: Int {
            let components = URLComponents(string: address)
            if let port = components?.port {
                return port
            }
            return 7359
        }

        var asServerState: ServerState {
            .init(
                urls: [url],
                currentURL: url,
                name: name,
                id: id,
                usersIDs: []
            )
        }

        enum CodingKeys: String, CodingKey {
            case address = "Address"
            case id = "Id"
            case name = "Name"
        }
    }
}
