//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct TabConfiguration: Codable, Hashable, Identifiable, Displayable, SystemImageable {

    let id: String
    var destination: TabDestination

    init(
        id: String = UUID().uuidString,
        destination: TabDestination
    ) {
        self.id = id
        self.destination = destination
    }

    var displayTitle: String {
        destination.displayTitle
    }

    var systemImage: String {
        destination.systemImage
    }

    static let home = Self(
        id: "default-content-group-provider",
        destination: .home
    )

    static let search = Self(
        id: "search",
        destination: .search
    )

    static let media = Self(
        id: "media",
        destination: .media
    )

    static func liveTV(
        id: String = "live-tv"
    ) -> Self {
        .init(
            id: id,
            destination: .liveTV
        )
    }

    static func contentView(
        id: String = UUID().uuidString,
        viewID: String
    ) -> Self {
        .init(
            id: id,
            destination: .contentView(id: viewID)
        )
    }

    static func admin(
        id: String = UUID().uuidString,
        destination: AdminTabDestination
    ) -> Self {
        .init(
            id: id,
            destination: .admin(destination)
        )
    }
}
