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

final class LibraryViewModel: ViewModel {

    @Default(.Customization.Library.gridPosterType)
    var libraryGridPosterType

    @Published
    var items: [BaseItemDto] = []
    @Published
    var totalPages = 0
    @Published
    var currentPage = 0
    @Published
    var hasNextPage = false

    // temp
    @Published
    var filters: LibraryFilters

    var parentID: String?
    var person: BaseItemPerson?
    var genre: NameGuidPair?
    var studio: NameGuidPair?

    private var pageItemSize: Int {
        let height = libraryGridPosterType == .portrait ? libraryGridPosterType.width * 1.5 : libraryGridPosterType.width / 1.77
        return UIScreen.itemsFillableOnScreen(width: libraryGridPosterType.width, height: height)
    }

    var enabledFilterType: [FilterType] {
        if genre == nil {
            return [.tag, .genre, .sortBy, .sortOrder, .filter]
        } else {
            return [.tag, .sortBy, .sortOrder, .filter]
        }
    }

    init(
        parentID: String? = nil,
        person: BaseItemPerson? = nil,
        genre: NameGuidPair? = nil,
        studio: NameGuidPair? = nil,
        filters: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], sortBy: [.name])
    ) {
        self.parentID = parentID
        self.person = person
        self.genre = genre
        self.studio = studio
        self.filters = filters

        super.init()

        $filters
            .sink(receiveValue: { newFilters in
                self.requestItemsAsync(with: newFilters, replaceCurrentItems: true)
            })
            .store(in: &cancellables)
    }

    func requestItemsAsync(with filters: LibraryFilters, replaceCurrentItems: Bool = false) {

        if replaceCurrentItems {
            self.items = []
        }

        let personIDs: [String] = [person].compactMap(\.?.id)
        let studioIDs: [String] = [studio].compactMap(\.?.id)
        let genreIDs: [String]
        if filters.withGenres.isEmpty {
            genreIDs = [genre].compactMap(\.?.id)
        } else {
            genreIDs = filters.withGenres.compactMap(\.id)
        }
        let sortBy = filters.sortBy.map(\.rawValue)
        let queryRecursive = Defaults[.Customization.showFlattenView] || filters.filters.contains(.isFavorite) ||
            self.person != nil ||
            self.genre != nil ||
            self.studio != nil
        let includeItemTypes: [BaseItemKind]
        if filters.filters.contains(.isFavorite) {
            includeItemTypes = [.movie, .series, .season, .episode, .boxSet]
        } else {
            includeItemTypes = [.movie, .series, .boxSet] + (Defaults[.Customization.showFlattenView] ? [] : [.folder])
        }

        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            startIndex: currentPage * pageItemSize,
            limit: pageItemSize,
            recursive: queryRecursive,
            searchTerm: nil,
            sortOrder: filters.sortOrder.compactMap { SortOrder(rawValue: $0.rawValue) },
            parentId: parentID,
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

            guard let self = self else { return }
            let totalPages = ceil(Double(response.totalRecordCount ?? 0) / Double(self.pageItemSize))

            self.totalPages = Int(totalPages)
            self.hasNextPage = self.currentPage < self.totalPages - 1
            self.items.append(contentsOf: response.items ?? [])
        })
        .store(in: &cancellables)
    }

    func requestNextPageAsync() {
        currentPage += 1
        requestItemsAsync(with: filters)
    }
}

extension UIScreen {

    static func itemsFillableOnScreen(width: CGFloat, height: CGFloat) -> Int {
        let screenSize = UIScreen.main.bounds.height * UIScreen.main.bounds.width
        let itemSize = width * height
        return Int(screenSize / itemSize)
    }
}
