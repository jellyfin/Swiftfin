//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

final class FilterViewModel: ViewModel {

    @Published
    var currentFilters: ItemFilterCollection

    @Published
    var allFilters: ItemFilterCollection = .all

    private let parent: (any LibraryParent)?

    init(
        parent: (any LibraryParent)? = nil,
        currentFilters: ItemFilterCollection = .default
    ) {
        self.parent = parent
        self.currentFilters = currentFilters
        super.init()
    }

    /// Sets the query filters from the parent
    func setQueryFilters() async {
        let queryFilters = await getQueryFilters()

        await MainActor.run {
            allFilters.genres = queryFilters.genres
            allFilters.tags = queryFilters.tags
            allFilters.years = queryFilters.years
        }
    }

    private func getQueryFilters() async -> (genres: [ItemGenre], tags: [ItemTag], years: [ItemYear]) {
        let parameters = Paths.GetQueryFiltersLegacyParameters(
            userID: userSession.user.id,
            parentID: parent?.id as? String
        )

        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        guard let response = try? await userSession.client.send(request) else { return ([], [], []) }

        let genres: [ItemGenre] = (response.value.genres ?? [])
            .map(ItemGenre.init)

        let tags = (response.value.tags ?? [])
            .map(ItemTag.init)

        // Manually sort so that most recent years are "first"
        let years = (response.value.years ?? [])
            .sorted(by: >)
            .map(ItemYear.init)

        return (genres, tags, years)
    }
}
