//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

// Since we don't view care to view seasons directly, this doesn't subclass from `ItemViewModel`.
// If we ever care for viewing seasons directly, subclass from that and have the library view model
// as a property.
typealias PagingSeasonViewModel = PagingLibraryViewModel<_PagingSeasonLibrary>

struct _PagingSeasonLibrary: PagingLibrary {

    let parent: BaseItemDto

    init(season: BaseItemDto) {
        self.parent = season
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {

        var parameters = Paths.GetEpisodesParameters()
        parameters.fields = [.overview]
        parameters.enableUserData = true
        parameters.isMissing = Defaults[.Customization.shouldShowMissingEpisodes] ? nil : false

        parameters.seasonID = parent.id

//        parameters.limit = pageState.pageSize
//        parameters.startIndex = pageState.page * pageState.pageSize

        let request = Paths.getEpisodes(
            seriesID: parent.id!,
            parameters: parameters
        )
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
