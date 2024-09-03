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

final class LatestInLibraryViewModel: PagingLibraryViewModel<BaseItemDto>, Identifiable {

    @Default(.Customization.Library.excludeLibraries)
    private var excludedLibraries

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = parameters()
        let request = Paths.getLatestMedia(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        let excludedLibraries = try await getExcludedLibraries()

        let includedItems = response.value
            .subtracting(excludedLibraries, using: \.parentID)

        return includedItems
    }

    private func parameters() -> Paths.GetLatestMediaParameters {

        var parameters = Paths.GetLatestMediaParameters()
        parameters.parentID = parent?.id
        parameters.fields = .MinimumFields
        parameters.enableUserData = true
        parameters.limit = pageSize

        return parameters
    }

    private func getExcludedLibraries() async throws -> [String] {
        let currentUserPath = Paths.getCurrentUser
        let response = try await userSession.client.send(currentUserPath)
        var allExcludedLibraries: [String] = excludedLibraries.map(\.id)

        if let myMediaExcludes = response.value.configuration?.myMediaExcludes {
            allExcludedLibraries.append(contentsOf: myMediaExcludes)
        }

        return allExcludedLibraries
    }
}
