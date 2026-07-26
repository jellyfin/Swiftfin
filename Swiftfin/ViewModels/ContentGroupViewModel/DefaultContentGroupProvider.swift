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
    var userSession: UserSession?

    let displayTitle: String = L10n.home
    let id: String = "default-content-group-provider"

    var refreshRequests: AnyPublisher<ContentGroupRefreshRequest, Never> {
        let defaultsChanges = Defaults.publisher(
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

        let libraryChanges = (userSession?.userLibraryChanges ?? Combine.Empty().eraseToAnyPublisher())
            .map { ContentGroupRefreshRequest() }

        return defaultsChanges
            .merge(with: libraryChanges)
            .eraseToAnyPublisher()
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

    @ContentGroupBuilder
    private func _makeGroups(userViews: [BaseItemDto]) -> [any ContentGroup] {
        HomePosterGroup.resume.makeGroup(
            library: ResumeItemsLibrary(mediaTypes: [.video]),
            viewContext: .isInResume
        )

        HomePosterGroup.nextUp.makeGroup(
            library: NextUpLibrary()
        )

        if Defaults[.Customization.Home.showRecentlyAdded] {
            HomePosterGroup.recentlyAdded.makeGroup(
                library: ItemLibrary(
                    parent: BaseItemDto(name: L10n.recentlyAdded.localizedCapitalized),
                    filters: .init(
                        itemTypes: [.movie, .series],
                        sortBy: [.dateCreated],
                        sortOrder: [.descending]
                    )
                )
            )
        }

        if Defaults[.Customization.Home.showRecentlyPlayed] {
            HomePosterGroup.recentlyPlayed.makeGroup(
                library: ItemLibrary(
                    parent: BaseItemDto(name: L10n.recentlyPlayed.localizedCapitalized),
                    filters: .init(
                        itemTypes: [.movie, .series],
                        sortBy: [.datePlayed],
                        sortOrder: [.descending],
                        traits: [.isPlayed]
                    )
                )
            )
        }

        HomePosterGroup.recommended.makeGroup(
            library: RecommendedProgramsLibrary()
        )

        userViews
            .map(LatestInLibrary.init)
            .map {
                HomePosterGroup.latestInLibrary.makeGroup(
                    library: $0,
                    id: "\(HomePosterGroup.latestInLibrary.id)-\($0.parent.pagingLibraryID)"
                )
            }
    }
}
