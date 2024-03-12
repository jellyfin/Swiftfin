//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import Get
import JellyfinAPI

// TODO: atow, this is only really used for tvOS tabs
final class ItemTypeLibraryViewModel: PagingLibraryViewModel<BaseItemDto> {

    let itemTypes: [BaseItemKind]

    init(itemTypes: [BaseItemKind]) {
        self.itemTypes = itemTypes

        super.init()
    }

    override func get(page: Int) async throws -> [BaseItemDto] {

        let parameters = itemParameters(for: page)
        let request = Paths.getItemsByUserID(userID: userSession.user.id, parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items ?? []
    }

    func itemParameters(for page: Int?) -> Paths.GetItemsByUserIDParameters {

        var parameters = Paths.GetItemsByUserIDParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.includeItemTypes = itemTypes
        parameters.isRecursive = true

        // Page size
        if let page {
            parameters.limit = pageSize
            parameters.startIndex = page * pageSize
        }

        return parameters
    }
}
