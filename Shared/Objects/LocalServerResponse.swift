//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation

struct LocalServerResponse: Codable, Hashable, Identifiable {

    let address: String
    let id: String
    let name: String

    var url: URL {
        URL(string: self.address)!
    }

    var host: String {
        let components = URLComponents(string: self.address)
        if let host = components?.host {
            return host
        }
        return self.address
    }

    var port: Int {
        let components = URLComponents(string: self.address)
        if let port = components?.port {
            return port
        }
        return 7359
    }
    
    var asStateServer: SwiftfinStore.State.Server {
        .init(uris: [address],
              currentURI: address,
              name: name,
              id: id,
              os: .emptyDash,
              version: .emptyDash,
              usersIDs: [])
    }

    enum CodingKeys: String, CodingKey {
        case address = "Address"
        case id = "Id"
        case name = "Name"
    }
}
