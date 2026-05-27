//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct DeepLink: Equatable {

    enum Destination: Equatable {
        case item(id: String)
        case library(id: String)
    }

    static let supportedSchemes = ["jellyfin", "widget-extension"]

    let serverID: String
    let userID: String
    let destination: Destination

    init?(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(),
              Self.supportedSchemes.contains(scheme)
        else {
            return nil
        }

        var components: [String] = []

        if let host = url.host(percentEncoded: false), host.isNotEmpty {
            components.append(host)
        }

        components.append(
            contentsOf: url.pathComponents
                .filter { $0 != "/" }
                .map { $0.removingPercentEncoding ?? $0 }
        )

        guard components.count == 4 else { return nil }

        self.serverID = components[0]
        self.userID = components[1]

        switch components[2].lowercased() {
        case "item":
            self.destination = .item(id: components[3])
        case "library":
            self.destination = .library(id: components[3])
        default:
            return nil
        }
    }
}
