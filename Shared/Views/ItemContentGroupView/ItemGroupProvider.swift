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

struct ItemGroupProvider: _ContentGroupProvider {

    let displayTitle: String
    let id: String

    let viewModel: _ItemViewModel

    init(displayTitle: String, id: String) {
        self.displayTitle = displayTitle
        self.id = id

        self.viewModel = .init(id: id)
    }

    func makeGroups(environment: Empty) async throws -> [any _ContentGroup] {
        await viewModel.refresh()

        guard viewModel.error == nil else {
            throw viewModel.error!
        }

        return try await _makeGroups(
            item: viewModel.item,
            itemID: id
        )
    }

    @ContentGroupBuilder
    private func _makeGroups(item: BaseItemDto, itemID: String) async throws -> [any _ContentGroup] {

        if UIDevice.isPad || UIDevice.isTV {
            EnhancedItemViewHeader(itemViewModel: viewModel)
        } else {
            if item.type == .movie || item.type == .series,
               Defaults[.Customization.itemViewType] == .enhanced,
               item.backdropImageTags?.isNotEmpty == true
            {
                EnhancedItemViewHeader(itemViewModel: viewModel)
            } else if item.type == .person || item.type == .musicArtist {
                PortraitItemViewHeader(itemViewModel: viewModel)
            } else {
                SimpleItemViewHeader(itemViewModel: viewModel)
            }
        }

        if item.type == .series {
            SeriesEpisodeContentGroup(viewModel: viewModel)
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
                                .musicArtist,
                                .person,
                            ],
                            parent: .init(name: element.displayTitle),
                            environment: .init(
                                filters: .init(
                                    genres: [.init(
                                        stringLiteral: element.id
                                    )]
                                )
                            )
                        )
                    )
                )
            }
        }

        if let studios = item.itemStudios, studios.isNotEmpty {
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
                                .musicArtist,
                                .person,
                            ],
                            parent: .init(
                                id: element.id,
                                name: element.displayTitle,
                                type: .studio
                            )
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
