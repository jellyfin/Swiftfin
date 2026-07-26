//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ItemContentGroupProvider {

    @ContentGroupBuilder
    func makeDownloadedGroups(item: BaseItemDto) async throws -> [any ContentGroup] {

        switch item.type {
        case .season, .series:
            SeriesEpisodeContentGroup(
                parent: item,
                playButtonItem: mediaPlayerItemProvider?.item
            )
        default:
            []
        }

        if let genres = item.itemGenres, genres.isNotEmpty {
            PillGroup(
                displayTitle: L10n.genres,
                id: "genres",
                elements: genres
            ) { router, element in
                var genreParent = BaseItemDto(
                    id: DownloadManager.libraryID,
                    name: element.displayTitle
                )
                genreParent.setDownloaded()

                router.route(
                    to: .contentGroup(
                        provider: ItemTypeContentGroupProvider(
                            itemTypes: [
                                BaseItemKind.movie,
                                .series,
                                .episode,
                                .boxSet,
                            ],
                            parent: genreParent,
                            environment: .init(filters: .init(genres: [element]))
                        )
                    )
                )
            }
        }

        switch item.type {
        case .boxSet, .person:
            try await ItemTypeContentGroupProvider(
                itemTypes: BaseItemKind.supportedCases.appending(.episode),
                parent: item
            )
            .makeGroups(environment: .default)
        case .series:
            try await ItemTypeContentGroupProvider(
                itemTypes: [.season],
                parent: item
            )
            .makeGroups(environment: .default)
        default:
            []
        }

        if item.type == .episode {
            PosterGroup(
                library: StaticLibrary(
                    title: L10n.season,
                    id: "seasons",
                    elements: {
                        var season = BaseItemDto(
                            id: item.seasonID,
                            name: item.seasonName,
                            seriesID: item.seriesID,
                            seriesName: item.seriesName,
                            type: .season
                        )
                        season.setDownloaded()
                        return [season]
                    }()
                ),
                posterSize: .small,
                environment: .init(isHeaderButtonEnabled: false)
            )
        }

        if let castAndCrew = item.people, castAndCrew.isNotEmpty {
            PosterGroup(
                id: "cast-and-crew",
                library: StaticLibrary(
                    title: L10n.castAndCrew.localizedCapitalized,
                    id: "cast-and-crew",
                    elements: castAndCrew
                ),
                posterDisplayType: .portrait,
                posterSize: .small
            )
        }

        AboutItemGroup(
            displayTitle: L10n.about,
            id: "about",
            item: item
        )
    }
}
