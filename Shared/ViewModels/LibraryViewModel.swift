//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import JellyfinAPI
import SwiftUI
import UIKit

// TODO: Look at refactoring
final class LibraryViewModel: PagingLibraryViewModel {

    let filterViewModel: FilterViewModel

    let parent: LibraryParent?
    let type: LibraryParentType
    private let saveFilters: Bool

    var libraryCoordinatorParameters: LibraryCoordinator.Parameters {
        if let parent = parent {
            return .init(parent: parent, type: type, filters: filterViewModel.currentFilters)
        } else {
            return .init(filters: filterViewModel.currentFilters)
        }
    }

    convenience init(filters: ItemFilters, saveFilters: Bool = false) {
        self.init(parent: nil, type: .library, filters: filters, saveFilters: saveFilters)
    }

    init(
        parent: LibraryParent?,
        type: LibraryParentType,
        filters: ItemFilters = .init(),
        saveFilters: Bool = false
    ) {
        self.parent = parent
        self.type = type
        self.filterViewModel = .init(parent: parent, currentFilters: filters)
        self.saveFilters = saveFilters
        super.init()

        filterViewModel.$currentFilters
            .sink { newFilters in
                self.requestItems(with: newFilters, replaceCurrentItems: true)

                if self.saveFilters, let id = self.parent?.id {
                    Defaults[.libraryFilterStore][id] = newFilters
                }
            }
            .store(in: &cancellables)
    }

    private func requestItems(with filters: ItemFilters, replaceCurrentItems: Bool = false) {

        if replaceCurrentItems {
            self.items = []
            self.currentPage = 0
            self.hasNextPage = true
        }

        var libraryID: String?
        var personIDs: [String]?
        var studioIDs: [String]?

        if let parent = parent {
            switch type {
            case .library, .folders:
                libraryID = parent.id
            case .person:
                personIDs = [parent].compactMap(\.id)
            case .studio:
                studioIDs = [parent].compactMap(\.id)
            }
        }

        var recursive = true
        let includeItemTypes: [BaseItemKind]

        if filters.filters.contains(ItemFilter.isFavorite.filter) {
            includeItemTypes = [.movie, .boxSet, .series, .season, .episode]
        } else if type == .folders {
            recursive = false
            includeItemTypes = [.movie, .boxSet, .series, .folder, .collectionFolder]
        } else {
            includeItemTypes = [.movie, .boxSet, .series]
        }

        var excludedIDs: [String]?

        if filters.sortBy.first == SortBy.random.filter {
            excludedIDs = items.compactMap(\.id)
        }

        let genreIDs = filters.genres.compactMap(\.id)
        let sortBy: [String] = filters.sortBy.map(\.filterName).appending("IsFolder")
        let sortOrder = filters.sortOrder.map { SortOrder(rawValue: $0.filterName) ?? .ascending }
        let itemFilters: [ItemFilter] = filters.filters.compactMap { .init(rawValue: $0.filterName) }

        Task {
            await MainActor.run {
                self.isLoading = true
            }

            let parameters = Paths.GetItemsParameters(
                userID: userSession.user.id,
                excludeItemIDs: excludedIDs,
                startIndex: currentPage * pageItemSize,
                limit: pageItemSize,
                isRecursive: recursive,
                sortOrder: sortOrder,
                parentID: libraryID,
                fields: ItemFields.allCases,
                includeItemTypes: includeItemTypes,
                filters: itemFilters,
                sortBy: sortBy,
                enableUserData: true,
                personIDs: personIDs,
                studioIDs: studioIDs,
                genreIDs: genreIDs,
                enableImages: true
            )
            let request = Paths.getItems(parameters: parameters)
            let response = try await userSession.client.send(request)

            guard let items = response.value.items, !items.isEmpty else {
                self.hasNextPage = false
                return
            }

            await MainActor.run {
                self.isLoading = false
                self.items.append(contentsOf: items)
            }
        }
    }

    override func _requestNextPage() {
        requestItems(with: filterViewModel.currentFilters)
    }
}
