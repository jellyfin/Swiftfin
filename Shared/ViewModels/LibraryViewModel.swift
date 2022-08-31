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
import UIKit

// TODO: Look at refactoring
final class LibraryViewModel: ViewModel {
    
    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType

    @Published
    var items: [BaseItemDto] = []
    @Published
    var filters: ItemFilters
    @Published
    private var currentPage = 0
    private var hasNextPage = true
    
    let parent: LibraryParent
    let type: LibraryParentType
    
    init(parent: LibraryParent,
         type: LibraryParentType,
         filters: ItemFilters) {
        self.parent = parent
        self.type = type
        self.filters = filters
        super.init()
        
        $filters
            .sink(receiveValue: { newFilters in
                self.requestItemsAsync(with: newFilters, replaceCurrentItems: true)
            })
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
        
        switch type {
        case .library, .folders:
            libraryID = parent.id
        case .person:
            personIDs = [parent].compactMap(\.id)
        case .studio:
            studioIDs = [parent].compactMap(\.id)
        }
        
        let genreIDs = filters.genres.compactMap(\.id)

        let sortBy = filters.sortBy.map(\.rawValue)

        let includeItemTypes: [BaseItemKind]

        if filters.filters.contains(.isFavorite) {
            includeItemTypes = [.movie, .boxSet, .series, .season, .episode]
        } else if type == .folders {
            includeItemTypes = [.collectionFolder]
        } else {
            includeItemTypes = [.movie, .series, .boxSet]
        }

        let excludedIDs: [String]?

        if filters.sortBy == [.random] {
            excludedIDs = items.compactMap(\.id)
        } else {
            excludedIDs = nil
        }
        
        let sortOrder = [SortOrder(rawValue: filters.sortOrder.rawValue) ?? .ascending]

        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            excludeItemIds: excludedIDs,
            startIndex: currentPage * pageItemSize,
            limit: pageItemSize,
            recursive: true,
            sortOrder: sortOrder,
            parentId: libraryID,
            fields: ItemFields.allCases,
            includeItemTypes: includeItemTypes,
            filters: filters.filters,
            sortBy: sortBy,
            tags: filters.tags,
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
            if filters.sortBy == [.random] {
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
        requestItemsAsync(with: filters)
    }
    
//    private func requestQueryFilters() {
//        FilterAPI.getQueryFilters(
//            userId: SessionManager.main.currentLogin.user.id,
//            parentId: self.parentId
//        )
//        .sink(receiveCompletion: { [weak self] completion in
//            self?.handleAPIRequestError(completion: completion)
//        }, receiveValue: { [weak self] queryFilters in
//            guard let self = self else { return }
//            self.possibleGenres = queryFilters.genres ?? []
//            self.possibleTags = queryFilters.tags ?? []
//        })
//        .store(in: &cancellables)
//    }
}

extension UIScreen {

    static func itemsFillableOnScreen(width: CGFloat, height: CGFloat) -> Int {
        let screenSize = UIScreen.main.bounds.height * UIScreen.main.bounds.width
        let itemSize = width * height
        return Int(screenSize / itemSize)
    }
}
