//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import FactoryKit
import Foundation
import JellyfinAPI

struct DefaultContentGroupProvider: ContentGroupProvider {

    @Injected(\.currentUserSession)
    private var userSession: UserSession?

    let displayTitle: String = L10n.home
    let id: String = "default-content-group-provider"

    var refreshRequests: AnyPublisher<ContentGroupRefreshRequest, Never> {
        let libraryChanges = (userSession?.userLibraryChanges ?? Combine.Empty().eraseToAnyPublisher())
            .map { ContentGroupRefreshRequest() }

        #if os(tvOS)
        return libraryChanges.eraseToAnyPublisher()
        #else
        return Defaults.publisher(
            keys: [
                .Customization.Home.showRecentlyAdded,
                .Customization.Home.showRecentlyPlayed,
                .Customization.Home.resumeNextUp,
                .Customization.Home.maxNextUp,
            ],
            options: []
        )
        .receive(on: RunLoop.main)
        .map { _ in ContentGroupRefreshRequest() }
        .merge(with: libraryChanges)
        .eraseToAnyPublisher()
        #endif
    }

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        guard let userSession else { return [] }

        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        let userViews = try await userSession.send(userViewsPath)
        let excludedLibraryIDs = userSession.userData.configuration?.latestItemsExcludes ?? []

        let resolvedUserViews = (userViews.value.items ?? [])
            .subtracting(excludedLibraryIDs, using: \.id)
            .intersecting(
                [
                    .homevideos,
                    .movies,
                    .musicvideos,
                    .tvshows,
                ],
                using: \.collectionType
            )

        return _makeGroups(userViews: resolvedUserViews)
    }
}
