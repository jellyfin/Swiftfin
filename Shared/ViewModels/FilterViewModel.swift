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

final class FilterViewModel: ViewModel, Stateful {

    enum Action {
        case getQueryFilters
        case cancel
    }

    enum State: Equatable {
        case initial
        case gettingQueryFilters
        case error(JellyfinAPIError)
        case results
    }

    @Published
    var currentFilters: ItemFilterCollection

    @Published
    var allFilters: ItemFilterCollection = .all

    var state: State = .initial

    private let parent: (any LibraryParent)?

    init(
        parent: (any LibraryParent)?,
        currentFilters: ItemFilterCollection
    ) {
        self.parent = parent
        self.currentFilters = currentFilters
        super.init()
    }

    func respond(to action: Action) -> State {
        .initial
    }

    func setQueryFilters() async {
        let queryFilters = await getQueryFilters()

        allFilters.genres = queryFilters.genres
        allFilters.tags = queryFilters.tags
        allFilters.years = queryFilters.years
    }

    private func getQueryFilters() async -> (genres: [ItemGenre], tags: [ItemTag], years: [ItemYear]) {
        let parameters = Paths.GetQueryFiltersLegacyParameters(
            userID: userSession.user.id,
            parentID: parent?.id as? String,
            includeItemTypes: nil,
            mediaTypes: nil
        )

        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        let response = try? await userSession.client.send(request)

        let genres: [ItemGenre] = (response?.value.genres ?? [])
            .map(ItemGenre.init)

        let tags = (response?.value.tags ?? [])
            .map(ItemTag.init)

        // Manually sort so that most recent years are "first"
        let years = (response?.value.years ?? [])
            .sorted(by: >)
            .map(ItemYear.init)

        return (genres, tags, years)
    }
}
