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

    @Published var librariesShowRecentlyAddedIDs: [String] = []
    @Published var libraries: [BaseItemDto] = []
    @Published var resumeItems: [BaseItemDto] = []
    @Published var nextUpItems: [BaseItemDto] = []

    // temp
    var recentFilterSet: LibraryFilters = LibraryFilters(filters: [], sortOrder: [.descending], sortBy: [.dateAdded])

    override init() {
        super.init()
        refresh()
    }

    func refresh() {
        LogManager.shared.log.debug("Refresh called.")
        UserViewsAPI.getUserViews(userId: SessionManager.main.currentLogin.user.id)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: ()
                case .failure(_):
                    self.libraries = []
                    self.handleAPIRequestError(completion: completion)
                }
            }, receiveValue: { response in

                var newLibraries: [BaseItemDto] = []

                response.items!.forEach { item in
                    LogManager.shared.log.debug("Retrieved user view: \(item.id!) (\(item.name ?? "nil")) with type \(item.collectionType ?? "nil")")
                    if item.collectionType == "movies" || item.collectionType == "tvshows" {
                        newLibraries.append(item)
                    }
                }

                UserAPI.getCurrentUser()
                    .trackActivity(self.loading)
                    .sink(receiveCompletion: { completion in
                        switch completion {
                        case .finished: ()
                        case .failure(_):
                            self.libraries = []
                            self.handleAPIRequestError(completion: completion)
                        }
                    }, receiveValue: { response in
                        let excludeIDs = response.configuration?.latestItemsExcludes != nil ? response.configuration!.latestItemsExcludes! : []

                        for excludeID in excludeIDs {
                            newLibraries.removeAll { library in
                                return library.id == excludeID
                            }
                        }

                        self.libraries = newLibraries
                    })
                    .store(in: &self.cancellables)
            })
            .store(in: &cancellables)

        ItemsAPI.getResumeItems(userId: SessionManager.main.currentLogin.user.id, limit: 12,
                                fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people],
                                mediaTypes: ["Video"],
                                imageTypeLimit: 1,
                                enableImageTypes: [.primary, .backdrop, .thumb])
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: ()
                case .failure(_):
                    self.resumeItems = []
                    self.handleAPIRequestError(completion: completion)
                }
            }, receiveValue: { response in
                LogManager.shared.log.debug("Retrieved \(String(response.items!.count)) resume items")

                self.resumeItems = response.items ?? []
            })
            .store(in: &cancellables)

        TvShowsAPI.getNextUp(userId: SessionManager.main.currentLogin.user.id, limit: 12,
                             fields: [.primaryImageAspectRatio, .seriesPrimaryImage, .seasonUserData, .overview, .genres, .people])
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished: ()
                case .failure(_):
                    self.nextUpItems = []
                    self.handleAPIRequestError(completion: completion)
                }
            }, receiveValue: { response in
                LogManager.shared.log.debug("Retrieved \(String(response.items!.count)) nextup items")

                self.nextUpItems = response.items ?? []
            })
            .store(in: &cancellables)
    }
}
