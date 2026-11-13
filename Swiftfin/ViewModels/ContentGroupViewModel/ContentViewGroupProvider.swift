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
        var resolvedGroups: [any ContentGroup] = []

        for group in configuration.groups {
            try await resolvedGroups.append(contentsOf: makeGroups(for: group))
        }

        return resolvedGroups
    }

    private func makeGroups(
        for group: ContentGroupConfiguration
    ) async throws -> [any ContentGroup] {
        switch group.source {
        case let .library(configuration):
            var parent = configuration.library?.baseItem ?? BaseItemDto()
            parent.name = group.displayTitle

            return [
                PosterGroup(
                    id: group.id,
                    library: ItemLibrary(
                        parent: parent,
                        filters: configuration.filters.resolvingLayoutItemTypes(
                            library: configuration.library
                        ),
                        useRememberedFilters: false
                    ),
                    posterDisplayType: configuration.poster.displayType,
                    posterSize: configuration.poster.size.posterSize
                ),
            ]

        case let .resume(configuration):
            return [
                PosterGroup(
                    id: group.id,
                    library: ResumeGroupLibrary(
                        id: group.id,
                        displayTitle: group.displayTitle,
                        configuration: configuration
                    ),
                    posterDisplayType: configuration.poster.displayType,
                    posterSize: configuration.poster.size.posterSize,
                    _viewContext: .isInResume
                ),
            ]

        case let .nextUp(configuration):
            return [
                PosterGroup(
                    id: group.id,
                    library: NextUpGroupLibrary(
                        id: group.id,
                        displayTitle: group.displayTitle,
                        configuration: configuration
                    ),
                    posterDisplayType: configuration.poster.displayType,
                    posterSize: configuration.poster.size.posterSize
                ),
            ]

        case let .liveTV(configuration):
            return makeLiveTVGroups(
                group: group,
                configuration: configuration
            )

        case let .genres(configuration):
            guard let userSession else { return [] }

            let itemTypes = configuration.itemTypes.isEmpty ?
                LayoutItemTypes.all :
                configuration.itemTypes
            let genres = try await retrieveGenres(
                configuration: configuration,
                itemTypes: itemTypes,
                userSession: userSession
            )

            return [
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
                },
            ]
        }
    }

    private func makeLiveTVGroups(
        group: ContentGroupConfiguration,
        configuration: LiveTVGroupConfiguration
    ) -> [any ContentGroup] {
        switch configuration.element {
        case .quickLinks:
            [
                PillGroup(
                    displayTitle: group.displayTitle,
                    id: group.id,
                    elements: LiveTVQuickLink.allCases
                ) { router, link in
                    switch link {
                    case .channels:
                        router.route(
                            to: .library(
                                library: ItemLibrary(
                                    parent: BaseItemDto(name: L10n.channels),
                                    filters: .init(itemTypes: [.liveTvChannel])
                                )
                            )
                        )

                    case .recordings:
                        router.route(to: .library(library: RecordingsLibrary()))
                    }
                },
            ]

        case .onNow:
            [
                makeLiveTVPosterGroup(
                    id: group.id,
                    title: group.displayTitle,
                    library: RecommendedProgramsLibrary(),
                    poster: configuration.poster
                ),
            ]

        case .recordings:
            [
                makeLiveTVPosterGroup(
                    id: group.id,
                    title: group.displayTitle,
                    library: RecordingsLibrary(),
                    poster: configuration.poster
                ),
            ]

        case let .programCategory(section):
            [
                makeLiveTVPosterGroup(
                    id: group.id,
                    title: group.displayTitle,
                    library: ProgramsLibrary(section: section),
                    poster: configuration.poster
                ),
            ]
        }
    }

    private func makeLiveTVPosterGroup<Library: PagingLibrary>(
        id: String,
        title: String,
        library: Library,
        poster: PosterGroupSettings
    ) -> any ContentGroup where Library.Element: LibraryElement, Library.Element: Poster {
        PosterGroup(
            id: id,
            library: TitledPagingLibrary(
                library: library,
                displayTitle: title,
                id: id
            ),
            posterDisplayType: poster.displayType,
            posterSize: poster.size.posterSize
        )
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

        var seenGenres: Set<String> = []

        return (response.value.items ?? [])
            .compactMap(\.name)
            .filter { seenGenres.insert($0).inserted }
    }
}
