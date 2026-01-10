//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct FavoritesContentGroupProvider: _ContentGroupProvider {

    let displayTitle: String = L10n.favorites
    let id: String = "favorites-content-group-provider"

    func makeGroups(environment: Empty) async throws -> [any _ContentGroup] {
        try await ItemTypeContentGroupProvider(
            itemTypes: [
                BaseItemKind.movie,
                .series,
                .boxSet,
                .episode,
                .musicVideo,
                .video,
                .liveTvProgram,
                .tvChannel,
                .musicArtist,
                .person,
            ]
        )
        .makeGroups(environment: .init(filters: .favorites))
    }
}
