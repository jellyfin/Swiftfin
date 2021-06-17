//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import ActivityIndicator
import Combine
import Foundation
import JellyfinAPI

final class HomeViewModel: ViewModel {

    @Published
    var librariesShowRecentlyAddedIDs = [String]()
    @Published
    var libraries = [BaseItemDto]()
    @Published
    var resumeItems = [BaseItemDto]()
    @Published
    var nextUpItems = [BaseItemDto]()
    
    // temp
    var recentFilterSet: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.descending], sortBy: ["DateCreated"])

    override init() {
        super.init()

        refresh()
    }

    func refresh() {
        UserAPI.getCurrentUser()
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { response in
                let libraries = response.configuration?.orderedViews ?? []
                self.librariesShowRecentlyAddedIDs = libraries.filter { element in
                    !(response.configuration?.latestItemsExcludes?.contains(element))!
                }
            })
            .store(in: &cancellables)

        UserViewsAPI.getUserViews(userId: SessionManager.current.user.user_id!)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { response in
                self.libraries = response.items ?? []
            })
            .store(in: &cancellables)

        ItemsAPI.getResumeItems(userId: SessionManager.current.user.user_id!, limit: 12,
                                fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                                mediaTypes: ["Video"], imageTypeLimit: 1, enableImageTypes: [.primary, .backdrop, .thumb])
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { response in
                self.resumeItems = response.items ?? []
            })
            .store(in: &cancellables)

        TvShowsAPI.getNextUp(userId: SessionManager.current.user.user_id!, limit: 12,
                             fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people])
            .trackActivity(loading)
            .sink(receiveCompletion: { result in
                print(result)
            }, receiveValue: { response in
                self.nextUpItems = response.items ?? []
            })
            .store(in: &cancellables)
    }
}
