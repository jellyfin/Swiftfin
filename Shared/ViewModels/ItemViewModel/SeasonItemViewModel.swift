//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

// TODO: after figuring out how to do bidirectional/offset in PagingLibraryViewModel,
//       implement paginating
final class SeasonItemViewModel: PagingLibraryViewModel<BaseItemDto> {

    init(season: BaseItemDto) {
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

extension SeasonItemViewModel: Hashable {

    static func == (lhs: SeasonItemViewModel, rhs: SeasonItemViewModel) -> Bool {
        lhs.parent as! BaseItemDto == rhs.parent as! BaseItemDto
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine((parent as! BaseItemDto).hashValue)
    }
}
