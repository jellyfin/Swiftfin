//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI
import OrderedCollections

struct ItemTypeContentGroupProvider: _ContentGroupProvider {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static var `default`: Self {
            .init(filters: .init())
        }
    }

    let id: String = ""
    let displayTitle: String = ""
    let systemImage: String = "heart.fill"

    let itemTypes: [BaseItemKind]
    let parent: BaseItemDto?

    init(
        itemTypes: [BaseItemKind],
        parent: BaseItemDto? = nil
    ) {
        self.itemTypes = itemTypes
        self.parent = parent
    }

    func makeGroups(environment: Environment) async throws -> [any _ContentGroup] {
        itemTypes.map { itemType in
            /// Server will edit filters if only boxset, add userView as workaround.
            let itemTypes = (itemType == .boxSet ? [.boxSet, .userView] : [itemType])

            var filters = environment.filters
            filters.itemTypes = itemTypes

            return PosterGroup(
                id: "\(parent?.id ?? "unknown")-\(itemType.rawValue)",
                library: PagingItemLibrary(
                    parent: .init(
                        id: parent?.id,
                        name: itemType.pluralDisplayTitle,
                        type: parent?.type
                    ),
                    filters: filters
                )
            )
        }
    }
}

struct SearchContentGroupProvider: _ContentGroupProvider {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static var `default`: Self {
            .init(filters: .init())
        }
    }

    let id: String = ""
    let displayTitle: String = ""
    let systemImage: String = "heart.fill"

    func makeGroups(environment: Environment) async throws -> [any _ContentGroup] {
        let itemTypes = try await ItemTypeContentGroupProvider(
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
            ]
        )
        .makeGroups(environment: .init(filters: environment.filters))

//        let itemTypes: [any _ContentGroup] = [
//            BaseItemKind.movie,
//            .series,
//            .boxSet,
//            .episode,
//            .musicVideo,
//            .video,
//            .liveTvProgram,
//            .tvChannel,
//            .musicArtist,
//            .person,
//        ]
//            .map { itemType in
//
//                var filters = environment.filters
//                filters.itemTypes = [itemType]
//
//                return PosterGroup(
//                    id: "search-\(itemType.rawValue)",
//                    library: PagingItemLibrary(
//                        parent: .init(
//                            id: nil,
//                            name: itemType.pluralDisplayTitle,
//                            type: itemType
//                        ),
//                        filters: filters
//                    )
//                )
//            }

        let people = PosterGroup(
            id: UUID().uuidString,
            library: PeopleLibrary(
                environment: .init(query: environment.filters.query)
            )
        )

        return itemTypes + [people]
    }
}

// struct MultiContentGroupProvider: _ContentGroupProvider {
//
//    let id: String = ""
//    let displayTitle: String = ""
//    let systemImage: String = "heart.fill"
//
//    let providers: [any _ContentGroupProvider]
//
//    func makeGroups() async throws -> [any _ContentGroup] {
//        try await providers.asyncFlatMap { try await $0.makeGroups() }
//    }
// }

extension Collection {

    func asyncFlatMap<T>(_ transform: (Element) async throws -> [T]) async throws -> [T] {
        var result: [T] = []
        for element in self {
            let transformed = try await transform(element)
            result.append(contentsOf: transformed)
        }
        return result
    }
}
