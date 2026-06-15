//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ItemGroupProvider: ContentGroupProvider {

    let displayTitle: String
    let id: String

    let viewModel: ItemViewModel

    init(displayTitle: String, id: String) {
        self.displayTitle = displayTitle
        self.id = id

        self.viewModel = .init(item: .init(id: id, name: displayTitle))
    }

    func makeGroups(environment: Empty) async throws -> [any ContentGroup] {
        await viewModel.refresh()

        if case let .error(error) = viewModel.state {
            throw error
        }

        return try await _makeGroups(
            item: viewModel.item,
            itemID: id
        )
    }

    @ContentGroupBuilder
    private func _makeGroups(item: BaseItemDto, itemID: String) async throws -> [any ContentGroup] {

        ItemHeaderContentGroup(item: item)

        // TODO: show age of person
        if let birthday = item.birthday?.formatted(date: .long, time: .omitted) {
            LabeledContentGroup(
                L10n.born,
                value: birthday
            )
        }

        if let deathday = item.deathday?.formatted(date: .long, time: .omitted) {
            LabeledContentGroup(
                L10n.died,
                value: deathday
            )
        }

        if let birthplace = item.birthplace {
            LabeledContentGroup(
                L10n.birthplace,
                value: birthplace
            )
        }

        if item.type == .series {
            SeriesEpisodeContentGroup(viewModel: SeriesItemViewModel(item: item))
        }

        if let genres = item.itemGenres, genres.isNotEmpty {
            PillGroup(
                displayTitle: L10n.genres,
                id: "genres",
                elements: genres
            ) { router, element in
                router.route(
                    to: .contentGroup(
                        provider: ItemTypeContentGroupProvider(
                            itemTypes: [
                                BaseItemKind.movie,
                                .series,
                                .boxSet,
                                .episode,
                                .musicVideo,
                                .video,
                                .liveTvProgram,
                                .tvChannel,
                                .person,
                            ],
                            parent: BaseItemDto(name: element.displayTitle),
                            environment: .init(filters: .init(genres: [element]))
                        )
                    )
                )
            }
        }

        if let studios = item.studios, studios.isNotEmpty {
            PillGroup(
                displayTitle: L10n.studios,
                id: "studios",
                elements: studios
            ) { router, element in
                router.route(
                    to: .contentGroup(
                        provider: ItemTypeContentGroupProvider(
                            itemTypes: [
                                BaseItemKind.movie,
                                .series,
                                .boxSet,
                                .episode,
                                .musicVideo,
                                .video,
                                .liveTvProgram,
                                .tvChannel,
                                .person,
                            ],
                            parent: BaseItemDto(id: element.id, name: element.displayTitle, type: .studio)
                        )
                    )
                )
            }
        }

        switch item.type {
        case .boxSet, .person, .musicArtist:
            try await ItemTypeContentGroupProvider(
                itemTypes: BaseItemKind.supportedCases
                    .appending(.episode)
                    .appending(.person),
                parent: item
            )
            .makeGroups(environment: .default)
        default: []
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

        PosterGroup(
            id: "special-features",
            library: SpecialFeaturesLibrary(itemID: itemID),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        PosterGroup(
            id: "similar-items",
            library: SimilarItemsLibrary(itemID: itemID),
            posterDisplayType: .landscape,
            posterSize: .small
        )

        AboutItemGroup(
            displayTitle: L10n.about,
            id: "about",
            item: item
        )
    }
}

private struct ItemHeaderContentGroup: ContentGroup {

    let id = "item-view-header"
    let item: BaseItemDto

    func body(with viewModel: Empty) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .bottom, spacing: 16) {
                PosterImage(
                    item: item,
                    type: item.preferredPosterDisplayType,
                    contentMode: .fit
                )
                .frame(width: UIDevice.isPhone ? 120 : 180)
                .posterShadow()

                VStack(alignment: .leading, spacing: 8) {
                    Text(item.displayTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(3)

                    DotHStack {
                        if let firstGenre = item.genres?.first {
                            Text(firstGenre)
                        }

                        if let premiereYear = item.premiereDateYear {
                            Text(premiereYear)
                        }

                        if let runtime = item.runtime {
                            Text(runtime, format: .hourMinuteAbbreviated)
                        }

                        if let seasonEpisodeLabel = item.seasonEpisodeLabel {
                            Text(seasonEpisodeLabel)
                        }
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let overview = item.overview, overview.isNotEmpty {
                Text(overview)
                    .font(.footnote)
                    .lineLimit(4)
            }
        }
        .edgePadding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
