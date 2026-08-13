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
        filtered(itemTypes: filters.itemTypes)
            .filtered(audioLanguages: filters.audioLanguages)
            .filtered(genres: filters.genres)
            .filtered(officialRatings: filters.officialRatings)
            .filtered(subtitleLanguages: filters.subtitleLanguages)
            .filtered(tags: filters.tags)
            .filtered(years: filters.years)
            .filtered(letters: filters.letter)
            .filtered(traits: filters.traits)
            .sorted(by: filters.sortBy.first, order: filters.sortOrder.first)
    }

    private func filtered(itemTypes: [BaseItemKind]) -> [BaseItemDto] {
        guard itemTypes.isNotEmpty else { return self }

        return filter { item in
            guard let type = item.type else { return false }
            return itemTypes.contains(type)
        }
    }

    private func filtered(audioLanguages: [ItemLanguage]) -> [BaseItemDto] {
        guard audioLanguages.isNotEmpty else { return self }

        let allowed = Set(audioLanguages.map(\.value))

        return filter { item in
            item.audioStreams
                .compactMap(\.language)
                .contains { allowed.contains($0) }
        }
    }

    private func filtered(subtitleLanguages: [ItemLanguage]) -> [BaseItemDto] {
        guard subtitleLanguages.isNotEmpty else { return self }

        let allowed = Set(subtitleLanguages.map(\.value))

        return filter { item in
            item.subtitleStreams
                .compactMap(\.language)
                .contains { allowed.contains($0) }
        }
    }

    private func filtered(genres: [ItemGenre]) -> [BaseItemDto] {
        guard genres.isNotEmpty else { return self }

        let allowed = Set(genres.map(\.value))

        return filter { item in
            guard let genres = item.genres else { return false }
            return !allowed.isDisjoint(with: genres)
        }
    }

    private func filtered(officialRatings: [ItemOfficialRating]) -> [BaseItemDto] {
        guard officialRatings.isNotEmpty else { return self }

        let allowed = Set(officialRatings.map(\.value))

        return filter { item in
            guard let rating = item.officialRating else { return false }
            return allowed.contains(rating)
        }
    }

    private func filtered(tags: [ItemTag]) -> [BaseItemDto] {
        guard tags.isNotEmpty else { return self }

        let allowed = Set(tags.map(\.value))

        return filter { item in
            guard let tags = item.tags else { return false }
            return !allowed.isDisjoint(with: tags)
        }
    }

    private func filtered(years: [ItemYear]) -> [BaseItemDto] {
        guard years.isNotEmpty else { return self }

        let allowed = Set(years.compactMap { Int($0.value) })

        return filter { item in
            guard let year = item.productionYear else { return false }
            return allowed.contains(year)
        }
    }

    private func filtered(letters: [ItemLetter]) -> [BaseItemDto] {
        guard letters.isNotEmpty else { return self }

        let allowed = Set(letters.map(\.value))

        return filter { $0.matches(letters: allowed) }
    }

    private func filtered(traits: [ItemTrait]) -> [BaseItemDto] {
        var items = self

        if traits.contains(.isFavorite) {
            items = items.filter { $0.userData?.isFavorite == true }
        }

        if traits.contains(.isPlayed) {
            items = items.filter { $0.userData?.isPlayed == true }
        }

        if traits.contains(.isUnplayed) {
            items = items.filter { $0.userData?.isPlayed != true }
        }

        return items
    }

    private func sorted(by sortBy: ItemSortBy?, order: ItemSortOrder?) -> [BaseItemDto] {
        guard let sortBy else { return self }

        if sortBy == .random {
            return shuffled()
        }

        let ascending = order == .ascending

        return sorted { lhs, rhs in
            let comparison = lhs.compare(to: rhs, by: sortBy)
            return ascending ? comparison : !comparison
        }
    }
}

private extension BaseItemDto {

    func matches(letters: Set<String>) -> Bool {
        guard let first = (sortName ?? displayTitle).first else { return false }

        if first.isLetter {
            return letters.contains(String(first).uppercased())
        }

        return letters.contains("#")
    }

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
