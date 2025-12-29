//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
enum ContentGroupProviderSetting: Equatable, Hashable, Storable {

    case `default`
    case custom(StoredContentGroupProvider)

    var provider: any _ContentGroupProvider {
        switch self {
        case .default:
            DefaultContentGroupProvider()
        case let .custom(provider):
            provider
        }
    }
}

@MainActor
enum ContentGroupSetting: Equatable, Hashable, Storable {

    case continueWatching(
        id: String,
        posterDisplayType: PosterDisplayType = .landscape,
        posterSize: PosterDisplayType.Size = .medium
    )

    case nextUp(
        id: String,
        posterDisplayType: PosterDisplayType = .portrait,
        posterSize: PosterDisplayType.Size = .medium
    )

    case library(
        id: String,
        displayTitle: String,
        libraryID: String,
        filters: ItemFilterCollection = .init(),
        posterDisplayType: PosterDisplayType = .portrait,
        posterSize: PosterDisplayType.Size = .medium
    )

    var group: any _ContentGroup {
        switch self {
        case let .continueWatching(
            id: id,
            posterDisplayType: posterDisplayType,
            posterSize: posterSize
        ):
            PosterGroup(
                id: id,
                library: ContinueWatchingLibrary(),
                posterDisplayType: posterDisplayType,
                posterSize: posterSize
            )
        case let .nextUp(
            id: id,
            posterDisplayType: posterDisplayType,
            posterSize: posterSize
        ):
            PosterGroup(
                id: id,
                library: NextUpLibrary(),
                posterDisplayType: posterDisplayType,
                posterSize: posterSize
            )
        case let .library(
            id: id,
            displayTitle: displayTitle,
            libraryID: libraryID,
            filters: filters,
            posterDisplayType: posterDisplayType,
            posterSize: posterSize
        ):
            PosterGroup(
                id: id,
                library: ItemLibrary(
                    parent: .init(id: libraryID, name: displayTitle),
                    filters: filters
                ),
                posterDisplayType: posterDisplayType,
                posterSize: posterSize
            )
        }
    }
}

struct StoredContentGroupProvider: _ContentGroupProvider, Equatable, Hashable, Storable {

    var displayTitle: String
    var id: String
    var systemImage: String
    var groups: [ContentGroupSetting]

    func makeGroups(environment: Empty) async throws -> [any _ContentGroup] {
        groups.map(\.group)
    }
}

extension StoredValues.Keys.User {

    static func customContentGroup(id: String) -> StoredValues.Key<ContentGroupProviderSetting> {
        StoredValues.Keys.CurrentUserKey(
            "__customContentGroup_\(id)",
            domain: "__customContentGroup_\(id)",
            default: .custom(
                .init(
                    displayTitle: "Custom \(id)",
                    id: id,
                    systemImage: "heart.fill",
                    groups: [.nextUp(
                        id: UUID().uuidString,
                        posterDisplayType: .portrait,
                        posterSize: .small
                    )]
                )
            )
        )
    }
}
