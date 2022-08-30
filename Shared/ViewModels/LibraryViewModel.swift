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

    @Published
    var items: [BaseItemDto] = []
    @Published
    private var currentPage = 0
    private var hasNextPage = true
    @Published
    var filters: LibraryFilters

    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType

    let library: BaseItemDto?
    let person: BaseItemPerson?
    let genre: NameGuidPair?
    let studio: NameGuidPair?

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
        library: BaseItemDto? = nil,
        person: BaseItemPerson? = nil,
        genre: NameGuidPair? = nil,
        studio: NameGuidPair? = nil,
        filters: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], sortBy: [.name])
    ) {
        self.library = library
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

        let includeItemTypes: [BaseItemKind]

        if filters.filters.contains(.isFavorite) {
            includeItemTypes = [.movie, .boxSet, .series, .season, .episode]
        } else if library?.collectionType == "folders" {
            includeItemTypes = [.collectionFolder]
        } else {
            includeItemTypes = [.movie, .series, .boxSet]
        }

        ItemsAPI.getItemsByUserId(
            userId: SessionManager.main.currentLogin.user.id,
            startIndex: currentPage * pageItemSize,
            limit: pageItemSize,
            recursive: true,
            searchTerm: nil,
            sortOrder: filters.sortOrder.compactMap { SortOrder(rawValue: $0.rawValue) },
            parentId: library?.id,
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

            self?.items.append(contentsOf: response.items ?? [])
        })
        .store(in: &cancellables)
    }

    func requestNextPageAsync() {
        guard hasNextPage else { return }
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
