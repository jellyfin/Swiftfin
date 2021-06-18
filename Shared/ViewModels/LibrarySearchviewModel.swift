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

final class LibrarySearchViewModel: ViewModel {
    @Published
    var items = [BaseItemDto]()

    @Published
    var searchQuery = ""
    var parentID: String?

    init(parentID: String?) {
        self.parentID = parentID
        super.init()

        $searchQuery
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
            .sink(receiveValue: search(with:))
            .store(in: &cancellables)
    }

    func search(with query: String) {
        ItemsAPI.getItemsByUserId(userId: SessionManager.current.user.user_id!, limit: 60, recursive: true, searchTerm: query,
                                  sortOrder: [.ascending], parentId: parentID,
                                  fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                                  includeItemTypes: ["Movie", "Series"], sortBy: ["SortName"], enableUserData: true, enableImages: true)
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.HandleAPIRequestCompletion(completion: completion)
            }, receiveValue: { [weak self] response in
                self?.items = response.items ?? []
            })
            .store(in: &cancellables)
    }
}
