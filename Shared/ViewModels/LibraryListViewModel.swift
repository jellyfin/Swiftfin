//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

final class LibraryListViewModel: ViewModel {

    @Published
    var libraries: [BaseItemDto] = []

    var filteredLibraries: [BaseItemDto] {
        var supportedLibraries = ["movies", "tvshows", "unknown"]

        if Defaults[.Experimental.liveTVAlphaEnabled] {
            supportedLibraries.append("livetv")
        }

        return libraries.filter { supportedLibraries.contains($0.collectionType ?? "unknown") }
    }

    // temp
    let withFavorites = LibraryFilters(filters: [.isFavorite], sortOrder: [], withGenres: [], sortBy: [])

    override init() {
        super.init()

        requestLibraries()
    }

    func requestLibraries() {
        UserViewsAPI.getUserViews(userId: SessionManager.main.currentLogin.user.id)
            .trackActivity(loading)
            .sink(receiveCompletion: { completion in
                self.handleAPIRequestError(completion: completion)
            }, receiveValue: { response in
                self.libraries = response.items ?? []
            })
            .store(in: &cancellables)
    }
}
