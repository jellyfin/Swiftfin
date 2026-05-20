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

@MainActor
final class DownloadLibraryViewModel: PagingLibraryViewModel<DownloadItem> {

    override var isDownloads: Bool {
        true
    }

    convenience init() {
        let parent = TitledLibraryParent(displayTitle: L10n.downloads, id: "downloads")
        self.init(parent: parent, filters: .default)

        let manager = Container.shared.downloadManager()

        manager.$downloads
            .receive(on: RunLoop.main)
            .dropFirst()
            .removeDuplicates(by: { $0.map(\.id) == $1.map(\.id) })
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.send(.refresh)
                }
            }
            .store(in: &cancellables)
    }

    override func get(page: Int) async throws -> [DownloadItem] {
        items(for: page)
    }

    override func getRandomItem() async -> DownloadItem? {
        items(for: nil).randomElement()
    }

    private func items(for page: Int?) -> [DownloadItem] {

        let manager = Container.shared.downloadManager()
        var items = manager.downloads

        if let filterViewModel {
            let filters = filterViewModel.currentFilters

            if filters.genres.isNotEmpty {
                let allowed = Set(filters.genres.map(\.value))
                items = items.filter {
                    guard let genres = $0.item.genres else { return false }
                    return !allowed.isDisjoint(with: genres)
                }
            }

            if filters.tags.isNotEmpty {
                let allowed = Set(filters.tags.map(\.value))
                items = items.filter {
                    guard let tags = $0.item.tags else { return false }
                    return !allowed.isDisjoint(with: tags)
                }
            }

            if filters.years.isNotEmpty {
                let allowed = Set(filters.years.compactMap { Int($0.value) })
                items = items.filter {
                    guard let year = $0.item.productionYear else { return false }
                    return allowed.contains(year)
                }
            }

            if filters.letter.isNotEmpty {
                let allowed = Set(filters.letter.map(\.value))
                items = items.filter {
                    let sortName = $0.item.sortName ?? $0.item.displayTitle
                    guard let first = sortName.first else { return false }
                    if first.isLetter {
                        return allowed.contains(String(first).uppercased())
                    }
                    return allowed.contains("#")
                }
            }

            if filters.traits.contains(where: { $0.value == ItemTrait.isFavorite.value }) {
                items = items.filter { $0.item.userData?.isFavorite == true }
            }
            if filters.traits.contains(where: { $0.value == ItemTrait.isPlayed.value }) {
                items = items.filter { $0.item.userData?.isPlayed == true }
            }
            if filters.traits.contains(where: { $0.value == ItemTrait.isUnplayed.value }) {
                items = items.filter { $0.item.userData?.isPlayed != true }
            }

            if let primarySort = filters.sortBy.first {
                let ascending = filters.sortOrder.first == .ascending
                items.sort { lhs, rhs in
                    let comparison = lhs.compare(to: rhs, by: primarySort)
                    return ascending ? comparison : !comparison
                }
            }
        }

        if let page {
            let startIndex = page * pageSize
            guard startIndex < items.count else { return [] }
            let endIndex = min(startIndex + pageSize, items.count)
            return Array(items[startIndex ..< endIndex])
        }

        return items
    }
}
