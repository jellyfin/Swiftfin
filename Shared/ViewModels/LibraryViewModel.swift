//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import JellyfinAPI
import SwiftUI
import UIKit

// TODO: Look at refactoring
final class LibraryViewModel: ViewModel {

    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType

    @Published
    var items: [BaseItemDto] = []

    let filterViewModel: FilterViewModel
    private var currentPage = 0
    private var hasNextPage = true

    let parent: LibraryParent?
    let type: LibraryParentType

    init(filters: ItemFilters) {
        self.parent = nil
        self.type = .library
        self.filterViewModel = .init(parent: nil, currentFilters: filters)
        super.init()

        filterViewModel.$currentFilters
            .sink { newFilters in
                self.requestItemsAsync(with: newFilters, replaceCurrentItems: true)
            }
            .store(in: &cancellables)
    }

    init(
        parent: LibraryParent,
        type: LibraryParentType,
        filters: ItemFilters = .init()
    ) {
        self.parent = parent
        self.type = type
        self.filterViewModel = .init(parent: parent, currentFilters: filters)
        super.init()

        filterViewModel.$currentFilters
            .sink { newFilters in
                self.requestItemsAsync(with: newFilters, replaceCurrentItems: true)
            }
            .store(in: &cancellables)
    }

    private var pageItemSize: Int {
        let height = libraryGridPosterType == .portrait ? libraryGridPosterType.width * 1.5 : libraryGridPosterType.width / 1.77
        return UIScreen.itemsFillableOnScreen(width: libraryGridPosterType.width, height: height)
    }

    func requestItemsAsync(with filters: ItemFilters, replaceCurrentItems: Bool = false) {

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
        let tags: [String] = filters.tags.map(\.filterName)

        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            excludeItemIds: excludedIDs,
            startIndex: currentPage * pageItemSize,
            limit: pageItemSize,
            recursive: recursive,
            sortOrder: sortOrder,
            parentId: libraryID,
            fields: ItemFields.allCases,
            includeItemTypes: includeItemTypes,
            filters: itemFilters,
            sortBy: sortBy,
            tags: tags,
            enableUserData: true,
            personIds: personIDs,
            studioIds: studioIDs,
            genreIds: genreIDs,
            enableImages: true
        )
        .trackActivity(loading)
        .sink(receiveCompletion: { [weak self] completion in
            self?.handleAPIRequestError(completion: completion)
        }, receiveValue: { [weak self] response in
            guard !(response.items?.isEmpty ?? false) else {
                self?.hasNextPage = false
                return
            }

            let items: [BaseItemDto]

            // There is a bug either with the request construction or the server when using
            // "Random" sort which causes duplicate items to be sent even though we send the
            // excluded ids. This causes shorter item additions when using "Random" over
            // consecutive calls. Investigation needs to be done to find the root of the problem.
            // Only filter for "Random" as an optimization.
            if filters.sortBy.first == SortBy.random.filter {
                items = response.items?.filter { !(self?.items.contains($0) ?? true) } ?? []
            } else {
                items = response.items ?? []
            }

            self?.items.append(contentsOf: items)
        })
        .store(in: &cancellables)
    }

    func requestNextPageAsync() {
        guard hasNextPage else { return }
        currentPage += 1
        requestItemsAsync(with: filterViewModel.currentFilters)
    }
}

extension UIScreen {

    static func itemsFillableOnScreen(width: CGFloat, height: CGFloat) -> Int {
        let screenSize = UIScreen.main.bounds.height * UIScreen.main.bounds.width
        let itemSize = width * height
        return Int(screenSize / itemSize)
    }
}
