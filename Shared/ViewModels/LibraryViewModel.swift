//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Combine
import Foundation
import JellyfinAPI

final class LibraryViewModel: ViewModel {
    var parentID: String?
    var person: BaseItemPerson?
    var genre: NameGuidPair?
    var studio: NameGuidPair?

    @Published
    var items = [BaseItemDto]()

    @Published
    var totalPages = 0
    @Published
    var currentPage = 0
    @Published
    var isCanNextPaging = false
    @Published
    var isCanPreviousPaging = false

    // temp
    var filters: LibraryFilters

    init(parentID: String? = nil,
         person: BaseItemPerson? = nil,
         genre: NameGuidPair? = nil,
         studio: NameGuidPair? = nil,
         filters: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], sortBy: ["SortName"]))
    {
        self.parentID = parentID
        self.person = person
        self.genre = genre
        self.studio = studio
        self.filters = filters
        super.init()

        refresh()
    }
    
    func refresh() {
        let personIDs: [String] = [person].compactMap(\.?.id)
        let studioIDs: [String] = [studio].compactMap(\.?.id)
        let genreIDs: [String] = [genre].compactMap(\.?.id)
        
        ItemsAPI.getItemsByUserId(userId: SessionManager.current.user.user_id!, startIndex: currentPage * 100, limit: 100, recursive: true, searchTerm: nil, sortOrder: filters.sortOrder, parentId: parentID, fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people], includeItemTypes: ["Movie", "Series"], filters: filters.filters, sortBy: filters.sortBy, enableUserData: true, personIds: personIDs, studioIds: studioIDs, genreIds: genreIDs, enableImages: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.HandleAPIRequestCompletion(completion: completion)
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                let totalPages = ceil(Double(response.totalRecordCount ?? 0) / 100.0)
                self.totalPages = Int(totalPages)
                self.isCanPreviousPaging = self.currentPage > 0
                self.isCanNextPaging = self.currentPage < self.totalPages - 1
                self.items = response.items ?? []
            })
            .store(in: &cancellables)
    }
    
    func requestNextPage() {
        currentPage += 1
        refresh()
    }
    
    func requestPreviousPage() {
        currentPage -= 1
        refresh()
    }
}
