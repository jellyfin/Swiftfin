//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension [BaseItemDto] {

    func filtered(using filters: ItemFilterCollection) -> [BaseItemDto] {
        var items = self

        if filters.itemTypes.isNotEmpty {
            items = items.filter {
                guard let type = $0.type else { return false }
                return filters.itemTypes.contains(type)
            }
        }

        if filters.genres.isNotEmpty {
            let allowed = Set(filters.genres.map(\.value))
            items = items.filter {
                guard let genres = $0.genres else { return false }
                return !allowed.isDisjoint(with: genres)
            }
        }

        if filters.tags.isNotEmpty {
            let allowed = Set(filters.tags.map(\.value))
            items = items.filter {
                guard let tags = $0.tags else { return false }
                return !allowed.isDisjoint(with: tags)
            }
        }

        if filters.years.isNotEmpty {
            let allowed = Set(filters.years.compactMap { Int($0.value) })
            items = items.filter {
                guard let year = $0.productionYear else { return false }
                return allowed.contains(year)
            }
        }

        if filters.letter.isNotEmpty {
            let allowed = Set(filters.letter.map(\.value))
            items = items.filter {
                let sortName = $0.sortName ?? $0.displayTitle
                guard let first = sortName.first else { return false }
                if first.isLetter {
                    return allowed.contains(String(first).uppercased())
                }
                return allowed.contains("#")
            }
        }

        if filters.traits.contains(.isFavorite) {
            items = items.filter { $0.userData?.isFavorite == true }
        }
        if filters.traits.contains(.isPlayed) {
            items = items.filter { $0.userData?.isPlayed == true }
        }
        if filters.traits.contains(.isUnplayed) {
            items = items.filter { $0.userData?.isPlayed != true }
        }

        if let primarySort = filters.sortBy.first {
            if primarySort == .random {
                return items.shuffled()
            }

            let ascending = filters.sortOrder.first == .ascending
            items.sort { lhs, rhs in
                let comparison = lhs.compare(to: rhs, by: primarySort)
                return ascending ? comparison : !comparison
            }
        }

        return items
    }
}

private extension BaseItemDto {

    func compare(to other: BaseItemDto, by sort: ItemSortBy) -> Bool {
        switch sort {
        case .sortName, .name:
            (sortName ?? displayTitle) < (other.sortName ?? other.displayTitle)
        case .premiereDate:
            (premiereDate ?? .distantPast) < (other.premiereDate ?? .distantPast)
        case .productionYear:
            (productionYear ?? 0) < (other.productionYear ?? 0)
        case .dateCreated:
            (dateCreated ?? .distantPast) < (other.dateCreated ?? .distantPast)
        case .datePlayed:
            (userData?.lastPlayedDate ?? .distantPast) < (other.userData?.lastPlayedDate ?? .distantPast)
        case .indexNumber:
            (parentIndexNumber ?? .max, indexNumber ?? .max) < (other.parentIndexNumber ?? .max, other.indexNumber ?? .max)
        case .playCount:
            (userData?.playCount ?? 0) < (other.userData?.playCount ?? 0)
        case .runtime:
            (runTimeTicks ?? 0) < (other.runTimeTicks ?? 0)
        case .communityRating:
            (communityRating ?? 0) < (other.communityRating ?? 0)
        case .criticRating:
            (criticRating ?? 0) < (other.criticRating ?? 0)
        default:
            (sortName ?? displayTitle) < (other.sortName ?? other.displayTitle)
        }
    }
}
