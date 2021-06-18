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
    var modifyedFilters = LibraryFilters()

    @Published
    var allGenres = [NameGuidPair]()
    @Published
    var allTags = [String]()
    @Published
    var allSortOrders = APISortOrder.allCases
    @Published
    var allSortBys = SortBy.allCases
    @Published
    var allItemFilters = ItemFilter.allCases
    @Published
    var enabledFilterType: [FilterType]

    init(filters: LibraryFilters? = nil,
         enabledFilterType: [FilterType] = [.tag, .genre, .sortBy, .sortOrder, .filter]) {
        self.enabledFilterType = enabledFilterType
        super.init()
        if let filters = filters {
            self.modifyedFilters = filters
        }
        refresh()
    }

    func refresh() {
        FilterAPI.getQueryFilters(userId: SessionManager.current.user.user_id!)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestCompletion(completion: completion)
            }, receiveValue: { [weak self] quertFilters in
                guard let self = self else { return }
                self.allGenres = quertFilters.genres ?? []
                self.allTags = quertFilters.tags ?? []
            })
            .store(in: &cancellables)
    }
}
