//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ItemTypeContentGroupProvider: ContentGroupProvider {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static var `default`: Self {
            .init(filters: .init())
        }
    }

    let id: String
    let displayTitle: String
    var environment: Environment
    let itemTypes: [BaseItemKind]
    let parent: BaseItemDto?

    init(
        itemTypes: [BaseItemKind],
        parent: BaseItemDto? = nil,
        environment: Environment = .default
    ) {
        self.id = UUID().uuidString
        self.displayTitle = parent?.displayTitle ?? ""
        self.itemTypes = itemTypes
        self.environment = environment
        self.parent = parent
    }

    func makeGroups(environment: Environment) async throws -> [any ContentGroup] {

        guard environment.filters.isNotEmpty || parent != nil else { return [] }

        return itemTypes.map { itemType in
            // Server will edit filters if only boxset, add userView as workaround.
            let itemTypes = (itemType == .boxSet ? [.boxSet, .userView] : [itemType])

            var filters = environment.filters
            filters.itemTypes = itemTypes

            if itemType == .episode {
                return EpisodeGroup(
                    library: ItemLibrary(
                        parent: .init(
                            id: parent?.id,
                            name: itemType.pluralDisplayTitle,
                            type: parent?.type
                        ),
                        filters: filters,
                        fields: [.overview]
                    )
                )
            } else {
                return PosterGroup(
                    id: "\(parent?.id ?? "unknown")-\(itemType.rawValue)",
                    library: ItemLibrary(
                        parent: .init(
                            id: parent?.id,
                            name: itemType.pluralDisplayTitle,
                            type: parent?.type
                        ),
                        filters: filters,
                        fields: itemType == .liveTvProgram ? [.channelInfo] : nil
                    ),
                    posterDisplayType: itemType.preferredPosterDisplayType
                )
            }
        }
    }
}
