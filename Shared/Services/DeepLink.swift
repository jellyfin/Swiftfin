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

        // TODO: able to launch library by ID without item pre-retrieval?
//        case library(id: String)
    }

    let serverID: String
    let userID: String
    let destination: Destination

    init?(_ url: URL) {
        guard let match = url.absoluteString.wholeMatch(
            of: /^swiftfin:\/\/(?<serverID>[A-Za-z0-9]+)\/(?<userID>[A-Za-z0-9]+)\/(?<destinationType>item|library)\/(?<destinationID>[A-Za-z0-9]+)\/?$/
        ) else { return nil }

        self.serverID = String(match.output.serverID)
        self.userID = String(match.output.userID)

        self.destination = .item(id: String(match.output.destinationID))
    }

    func route() -> NavigationRoute {
        switch destination {
        case let .item(id):
            .item(id: id)
//        case let .library(id):
//            let library = try await getItem(id: id, userSession: session)
//            return .library(viewModel: ItemLibraryViewModel(parent: library))
        }
    }
}

enum DeepLinkError: Error {
    case missingServer(String)
    case missingUser(String)
}
