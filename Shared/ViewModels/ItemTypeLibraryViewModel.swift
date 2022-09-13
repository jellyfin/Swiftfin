//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class ItemTypeLibraryViewModel: PagingLibraryViewModel {

    let itemTypes: [BaseItemKind]
    let filterViewModel: FilterViewModel

    init(itemTypes: [BaseItemKind], filters: ItemFilters) {
        self.itemTypes = itemTypes
        self.filterViewModel = .init(parent: nil, currentFilters: filters)
        super.init()

        filterViewModel.$currentFilters
            .sink { newFilters in
                self.requestItems(with: newFilters, replaceCurrentItems: true)
            }
            .store(in: &cancellables)
    }

    private func requestItems(with filters: ItemFilters, replaceCurrentItems: Bool = false) {

        if replaceCurrentItems {
            self.items = []
            self.currentPage = 0
            self.hasNextPage = true
        }

        let genreIDs = filters.genres.compactMap(\.id)
        let sortBy: [String] = filters.sortBy.map(\.filterName).appending("IsFolder")
        let sortOrder = filters.sortOrder.map { SortOrder(rawValue: $0.filterName) ?? .ascending }
        let itemFilters: [ItemFilter] = filters.filters.compactMap { .init(rawValue: $0.filterName) }
        let tags: [String] = filters.tags.map(\.filterName)

        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            startIndex: currentPage * pageItemSize,
            limit: pageItemSize,
            recursive: true,
            sortOrder: sortOrder,
            fields: ItemFields.allCases,
            includeItemTypes: itemTypes,
            filters: itemFilters,
            sortBy: sortBy,
            tags: tags,
            enableUserData: true,
            genreIds: genreIDs
        )
        .trackActivity(loading)
        .sink { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        } receiveValue: { [weak self] response in
            guard let items = response.items, !items.isEmpty else {
                self?.hasNextPage = false
                return
            }

            self?.items.append(contentsOf: items)
        }
        .store(in: &cancellables)
    }

    override func _requestNextPage() {
        requestItems(with: filterViewModel.currentFilters)
    }
}
