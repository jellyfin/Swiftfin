//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct SearchContentGroupProvider: _ContentGroupProvider {

    struct Environment: WithDefaultValue {
        var filters: ItemFilterCollection

        static var `default`: Self {
            .init(filters: .init())
        }
    }

    let id: String = ""
    let displayTitle: String = ""
    var environment: Environment = .default

    @ContentGroupBuilder
    func makeGroups(environment: Environment) async throws -> [any _ContentGroup] {
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
                .person,
            ]
        )
        .makeGroups(environment: .init(filters: environment.filters))

        PosterGroup(
            id: UUID().uuidString,
            library: PeopleLibrary(
                environment: .init(query: environment.filters.query)
            )
        )
    }
}
