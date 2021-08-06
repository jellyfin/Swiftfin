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

enum FilterType {
    case tag
    case genre
    case sortOrder
    case sortBy
    case filter
}

final class LibraryFilterViewModel: ViewModel {
    @Published
    var modifiedFilters = LibraryFilters()

    @Published
    var possibleGenres = [NameGuidPair]()
    @Published
    var possibleTags = [String]()
    @Published
    var possibleSortOrders = APISortOrder.allCases
    @Published
    var possibleSortBys = SortBy.allCases
    @Published
    var possibleItemFilters = ItemFilter.supportedTypes
    @Published
    var enabledFilterType: [FilterType]
    @Published
    var selectedSortOrder: APISortOrder = .descending
    @Published
    var selectedSortBy: SortBy = .name

    var parentId: String = ""

    func updateModifiedFilter() {
        modifiedFilters.sortOrder = [selectedSortOrder]
        modifiedFilters.sortBy = [selectedSortBy]
    }

    func resetFilters() {
        modifiedFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], tags: [], sortBy: [.name])
    }

    init(filters: LibraryFilters? = nil,
         enabledFilterType: [FilterType] = [.tag, .genre, .sortBy, .sortOrder, .filter], parentId: String) {
        self.enabledFilterType = enabledFilterType
        self.selectedSortBy = filters?.sortBy.first ?? .name
        self.selectedSortOrder = filters?.sortOrder.first ?? .descending
        self.parentId = parentId

        super.init()
        if let filters = filters {
            self.modifiedFilters = filters
        }
        requestQueryFilters()
    }

    func requestQueryFilters() {
        FilterAPI.getQueryFilters(userId: SessionManager.current.user.user_id!, parentId: self.parentId)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestCompletion(completion: completion)
            }, receiveValue: { [weak self] queryFilters in
                guard let self = self else { return }
                self.possibleGenres = queryFilters.genres ?? []
                self.possibleTags = queryFilters.tags ?? []
            })
            .store(in: &cancellables)
    }
}
