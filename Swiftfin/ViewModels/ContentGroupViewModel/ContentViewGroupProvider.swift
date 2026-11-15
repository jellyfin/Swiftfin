//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import Foundation
import JellyfinAPI

struct ContentViewGroupProvider: ContentGroupProvider {

    @Injected(\.currentUserSession)
    private var userSession: UserSession?

    let configuration: ContentViewConfiguration

    var id: String {
        configuration.id
    }

    var displayTitle: String {
        configuration.displayTitle
    }

    init(configuration: ContentViewConfiguration) {
        self.configuration = configuration
    }

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        for group in configuration.groups {
            try await makeGroups(for: group)
        }
    }

    @ContentGroupBuilder
    private func makeGroups(
        for group: ContentGroupConfiguration
    ) async throws -> [any ContentGroup] {
        switch group.source {
        case let .library(configuration):
            var parent = configuration.library?.baseItem ?? BaseItemDto()
            parent.name = group.displayTitle

            PosterGroup(
                id: group.id,
                library: ItemLibrary(
                    parent: parent,
                    filters: configuration.filters,
                    useRememberedFilters: false
                ),
                posterDisplayType: configuration.poster.displayType,
                posterSize: configuration.poster.size
            )

        case let .resume(configuration):
            PosterGroup(
                id: group.id,
                library: ResumeItemsLibrary(
                    mediaTypes: nil,
                    itemTypes: configuration.itemTypes,
                    parent: .init(displayTitle: group.displayTitle, id: group.id),
                    parentID: configuration.parent?.id,
                    searchTerm: configuration.searchTerm
                ),
                posterDisplayType: configuration.poster.displayType,
                posterSize: configuration.poster.size,
                _viewContext: .isInResume
            )

        case let .nextUp(configuration):
            PosterGroup(
                id: group.id,
                library: NextUpLibrary(
                    environment: .init(
                        enableRewatching: configuration.enableRewatching,
                        maxNextUp: TimeInterval(configuration.maxDays ?? 0) * 24 * 60 * 60
                    ),
                    parent: .init(displayTitle: group.displayTitle, id: group.id),
                    parentID: configuration.library?.id,
                    seriesID: configuration.series?.id
                ),
                posterDisplayType: configuration.poster.displayType,
                posterSize: configuration.poster.size
            )

        case let .liveTV(configuration):
            makeLiveTVGroups(
                group: group,
                configuration: configuration
            )

        case let .genres(configuration):
            if let userSession {
                let itemTypes = configuration.itemTypes.isEmpty ?
                    BaseItemKind.supportedCases :
                    configuration.itemTypes
                let genres = try await retrieveGenres(
                    configuration: configuration,
                    itemTypes: itemTypes,
                    userSession: userSession
                )

                PillGroup(
                    displayTitle: group.displayTitle,
                    id: group.id,
                    elements: genres
                ) { router, genre in
                    var parent = configuration.parent?.baseItem ?? BaseItemDto()
                    parent.name = genre

                    router.route(
                        to: .library(
                            library: ItemLibrary(
                                parent: parent,
                                filters: .init(
                                    genres: [ItemGenre(stringLiteral: genre)],
                                    itemTypes: itemTypes
                                ),
                                useRememberedFilters: false
                            )
                        )
                    )
                }
            }
        }
    }

    @ContentGroupBuilder
    private func makeLiveTVGroups(
        group: ContentGroupConfiguration,
        configuration: LiveTVGroupConfiguration
    ) -> [any ContentGroup] {
        switch configuration.element {
        case .quickLinks:
            PillGroup(
                displayTitle: group.displayTitle,
                id: group.id,
                elements: [LiveTVGroupProvider.QuickLink.channels, .recordings]
            ) { router, link in
                router.route(to: link.route)
            }

        case .onNow:
            PosterGroup(
                id: group.id,
                library: RecommendedProgramsLibrary(parent: .init(displayTitle: group.displayTitle, id: group.id)),
                posterDisplayType: configuration.poster.displayType,
                posterSize: configuration.poster.size
            )

        case .recordings:
            PosterGroup(
                id: group.id,
                library: RecordingsLibrary(parent: .init(displayTitle: group.displayTitle, id: group.id)),
                posterDisplayType: configuration.poster.displayType,
                posterSize: configuration.poster.size
            )

        case let .programCategory(section):
            PosterGroup(
                id: group.id,
                library: ProgramsLibrary(
                    section: section,
                    parent: .init(displayTitle: group.displayTitle, id: group.id)
                ),
                posterDisplayType: configuration.poster.displayType,
                posterSize: configuration.poster.size
            )
        }
    }

    private func retrieveGenres(
        configuration: GenresGroupConfiguration,
        itemTypes: [BaseItemKind],
        userSession: UserSession
    ) async throws -> [String] {
        var parameters = Paths.GetGenresParameters()
        parameters.includeItemTypes = itemTypes
        parameters.parentID = configuration.parent?.id
        parameters.searchTerm = configuration.searchTerm
        parameters.userID = userSession.user.id

        let request = Paths.getGenres(parameters: parameters)
        let response = try await userSession.client.send(request)

        return (response.value.items ?? [])
            .compactMap(\.name)
            .uniqued { $0 }
    }
}
