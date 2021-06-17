//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import Foundation
import JellyfinAPI

final class LibraryListViewModel: ViewModel {
    @Published
    var libraries = [BaseItemDto]()

    // temp
    var withFavorites = LibraryFilters(filters: [.isFavorite], sortOrder: [], withGenres: [], sortBy: [])

    override init() {
        super.init()

        libraries.append(.init(name: "Favorites", id: "favorites"))
        libraries.append(.init(name: "Genres", id: "genres"))
        refresh()
    }

    func refresh() {
        UserViewsAPI.getUserViews(userId: SessionManager.current.user.user_id!)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { response in
                self.libraries.append(contentsOf: response.items ?? [])
            })
            .store(in: &cancellables)
    }
}
