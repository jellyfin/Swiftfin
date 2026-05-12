//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI

// TODO: Switch over to the new PagingLibrary type when available

final class DownloadLibraryViewModel: PagingLibraryViewModel<DownloadItemDto> {

    override var isDownloads: Bool {
        true
    }

    convenience init() {
        let parent = TitledLibraryParent(displayTitle: L10n.downloads, id: "downloads")
        self.init(parent: parent, filters: .default)

        let manager = Container.shared.downloadManager()

        manager.$completedItems
            .receive(on: RunLoop.main)
            .dropFirst()
            .removeDuplicates(by: { $0.map(\.record.id) == $1.map(\.record.id) })
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.send(.refresh)
                }
            }
            .store(in: &cancellables)
    }

    override func get(page: Int) async throws -> [DownloadItemDto] {
        let manager = Container.shared.downloadManager()
        let filtered = apply(filterViewModel?.currentFilters, to: manager.completedItems)

        let startIndex = page * pageSize
        guard startIndex < filtered.count else { return [] }

        let endIndex = min(startIndex + pageSize, filtered.count)

        return Array(filtered[startIndex ..< endIndex])
    }

    private func apply(_ filters: ItemFilterCollection?, to items: [DownloadItemDto]) -> [DownloadItemDto] {
        guard let filters else { return items }

        var filtered = items

        if filters.genres.isNotEmpty {
            let allowed = Set(filters.genres.map(\.value))
            filtered = filtered.filter { item in
                guard let genres = item.item.genres else { return false }
                return !allowed.isDisjoint(with: genres)
            }
        }

        if filters.tags.isNotEmpty {
            let allowed = Set(filters.tags.map(\.value))
            filtered = filtered.filter { item in
                guard let itemTags = item.item.tags else { return false }
                return !allowed.isDisjoint(with: itemTags)
            }
        }

        if filters.years.isNotEmpty {
            let allowed = Set(filters.years.compactMap { Int($0.value) })
            filtered = filtered.filter { item in
                guard let year = item.item.productionYear else { return false }
                return allowed.contains(year)
            }
        }

        if filters.letter.isNotEmpty {
            let allowed = Set(filters.letter.map(\.value))
            filtered = filtered.filter { item in
                let sortName = item.item.sortName ?? item.item.displayTitle
                guard let firstChar = sortName.first else { return false }
                if firstChar.isLetter {
                    return allowed.contains(String(firstChar).uppercased())
                }
                return allowed.contains("#")
            }
        }

        if filters.traits.contains(where: { $0.value == ItemTrait.isFavorite.value }) {
            filtered = filtered.filter { $0.item.userData?.isFavorite == true }
        }
        if filters.traits.contains(where: { $0.value == ItemTrait.isPlayed.value }) {
            filtered = filtered.filter { $0.item.userData?.isPlayed == true }
        }
        if filters.traits.contains(where: { $0.value == ItemTrait.isUnplayed.value }) {
            filtered = filtered.filter { $0.item.userData?.isPlayed != true }
        }

        let ascending = filters.sortOrder.first == .ascending
        if let primarySort = filters.sortBy.first {
            filtered.sort { lhs, rhs in
                let comparison = lhs.compare(to: rhs, by: primarySort)
                return ascending ? comparison : !comparison
            }
        }

        return filtered
    }
}
