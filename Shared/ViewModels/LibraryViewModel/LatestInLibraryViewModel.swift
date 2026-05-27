//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class LatestInLibraryViewModel: PagingLibraryViewModel<BaseItemDto>, Identifiable {

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = try parameters(user: authenticatedUser)
        let request = Paths.getLatestMedia(parameters: parameters)
        let response = try await send(request)

        return response.value
    }

    private func parameters(user: UserState) -> Paths.GetLatestMediaParameters {

        var parameters = Paths.GetLatestMediaParameters()
        parameters.parentID = parent?.id
        parameters.fields = .MinimumFields
        parameters.enableUserData = true
        parameters.limit = pageSize

        if user.data.configuration?.isHidePlayedInLatest == true {
            parameters.isPlayed = false
        }

        return parameters
    }
}
