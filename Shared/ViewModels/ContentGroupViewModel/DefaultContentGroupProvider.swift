//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI

// TODO: rename `HomeContentGroupProvider`

struct DefaultContentGroupProvider: _ContentGroupProvider {

    @Injected(\.currentUserSession)
    var userSession: UserSession!

    let displayTitle: String = L10n.home
    let id: String = "default-content-group-provider"
    let systemImage: String = "house.fill"

    @ContentGroupBuilder
    func makeGroups(environment: Empty) async throws -> [any _ContentGroup] {
        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        let userViews = try await userSession.client.send(userViewsPath)
        let excludedLibraryIDs = userSession.user.data.configuration?.latestItemsExcludes ?? []

        PosterGroup(
            library: ContinueWatchingLibrary(),
            posterDisplayType: .landscape,
            posterSize: .medium
        )

        PosterGroup(
            library: NextUpLibrary()
        )

        PosterGroup(
            library: ItemLibrary(
                parent: .init(
                    name: L10n.recentlyAdded
                ),
                filters: .init(
                    itemTypes: [.movie, .series],
                    sortBy: [.dateCreated],
                    sortOrder: [.descending]
                )
            )
        )

        (userViews.value.items ?? [])
            .intersecting(
                [
                    .homevideos,
                    .movies,
                    .musicvideos,
                    .tvshows,
                ],
                using: \.collectionType
            )
            .subtracting(excludedLibraryIDs, using: \.id)
            .map(LatestInLibrary.init)
            .map {
                PosterGroup(
                    library: $0,
                    posterDisplayType: .portrait
                )
            }
    }
}
