//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

extension DefaultContentGroupProvider {

    @ContentGroupBuilder
    func _makeGroups(userViews: [BaseItemDto]) -> [any ContentGroup] {
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
