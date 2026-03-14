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

        let parameters = parameters()
        let request = Paths.getLatestMedia(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value
    }

    private func parameters() -> Paths.GetLatestMediaParameters {

        var parameters = Paths.GetLatestMediaParameters()
        parameters.userID = userSession.user.id
        parameters.parentID = parent?.id
        parameters.fields = .MinimumFields
        parameters.enableUserData = true
        parameters.limit = pageSize

        return parameters
    }
}
