//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

// Since we don't view care to view seasons directly, this doesn't subclass from `ItemViewModel`.
// If we ever care for viewing seasons directly, subclass from that and have the library view model
// as a property.
final class SeasonItemViewModel: PagingLibraryViewModel<BaseItemDto>, Identifiable {

    let season: BaseItemDto

    var id: String? {
        season.id
    }

    init(season: BaseItemDto) {
        self.season = season
        super.init(parent: season)
    }

    override func get(page: Int) async throws -> [BaseItemDto] {

        var parameters = Paths.GetEpisodesParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.isMissing = Defaults[.Customization.shouldShowMissingEpisodes] ? nil : false
        parameters.seasonID = parent!.id
        parameters.userID = userSession.user.id

//        parameters.startIndex = page * pageSize
//        parameters.limit = pageSize

        let request = Paths.getEpisodes(
            seriesID: parent!.id!,
            parameters: parameters
        )
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }
}
