//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import FactoryKit
import Foundation
import JellyfinAPI

struct DefaultContentGroupProvider: ContentGroupProvider {

    @Injected(\.currentUserSession)
    var userSession: UserSession?

    let displayTitle: String = L10n.home
    let id: String = "default-content-group-provider"

    private var supportedLatestCollectionTypes: [CollectionType] {
        #if os(iOS)
        [.homevideos, .movies, .music, .musicvideos, .tvshows]
        #else
        [.homevideos, .movies, .musicvideos, .tvshows]
        #endif
    }

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        guard let userSession else { return [] }
        let parameters = Paths.GetUserViewsParameters(userID: userSession.user.id)
        let userViewsPath = Paths.getUserViews(parameters: parameters)
        let userViews = try await userSession.client.send(userViewsPath)
        let excludedLibraryIDs = userSession.user.data.configuration?.latestItemsExcludes ?? []

        let resolvedUserViews = (userViews.value.items ?? []).subtracting(excludedLibraryIDs, using: \.id)
            .intersecting(
                supportedLatestCollectionTypes,
                using: \.collectionType
            )

        return _makeGroups(userViews: resolvedUserViews)
    }

    @ContentGroupBuilder
    private func _makeGroups(userViews: [BaseItemDto]) -> [any ContentGroup] {

        #if os(tvOS)
        let cinematicSelectionContentGroup = CinematicSelectionContentGroup(
            resumeLibrary: ResumeItemsLibrary(mediaTypes: [.video]),
            recentlyAddedLibrary: RecentlyAddedLibrary()
        )

        cinematicSelectionContentGroup
        #else
        PosterGroup(
            library: ResumeItemsLibrary(mediaTypes: [.video]),
            posterDisplayType: .landscape,
            posterSize: .medium,
            _viewContext: .isInResume
        )
        #endif

        PosterGroup(
            library: NextUpLibrary()
        )

        if Defaults[.Customization.Home.showRecentlyAdded] {
            #if os(tvOS)
            CinematicRecentlyAddedContentGroup(
                viewModel: cinematicSelectionContentGroup.viewModel
            )
            #else
            PosterGroup(
                library: ItemLibrary(
                    parent: BaseItemDto(name: L10n.recentlyAdded),
                    filters: .init(
                        itemTypes: [.movie, .series],
                        sortBy: [.dateCreated],
                        sortOrder: [.descending]
                    )
                )
            )
            #endif
        }

        userViews.map { userView in
            PosterGroup(
                library: LatestInLibrary(library: userView),
                posterDisplayType: latestPosterDisplayType(for: userView)
            )
        }
    }

    private func latestPosterDisplayType(for library: BaseItemDto) -> PosterDisplayType {
        #if os(iOS)
        if library.collectionType == .music {
            return .square
        }
        #endif

        return .landscape
    }
}
