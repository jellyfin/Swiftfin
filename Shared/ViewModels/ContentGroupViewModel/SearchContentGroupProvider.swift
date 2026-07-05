//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
struct SearchContentGroupProvider: ContentGroupProvider {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static var `default`: Self {
            .init(filters: .init())
        }
    }

    let id: String = UUID().uuidString
    let displayTitle: String = L10n.search
    let filterViewModel: FilterViewModel
    var environment: Environment

    init() {
        let filterViewModel: FilterViewModel = .init()

        self.filterViewModel = filterViewModel
        self.environment = .init(filters: filterViewModel.currentFilters)
    }

    @ContentGroupBuilder
    func makeGroups(environment: Environment) async throws -> [any ContentGroup] {
        try await ItemTypeContentGroupProvider(
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
            ]
        )
        .makeGroups(environment: .init(filters: environment.filters))

        PosterGroup(
            library: PeopleLibrary(
                environment: .init(query: environment.filters.query)
            )
        )
    }
}
