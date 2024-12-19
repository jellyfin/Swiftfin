//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

class PersonInfoViewModel: ItemInfoViewModel<PersonLookupInfo> {

    // MARK: - Return Matching People

    override func searchItem(_ personLookupInfo: PersonLookupInfo) async throws -> [RemoteSearchResult] {
        guard let itemId = item.id, item.type == .person else {
            return []
        }

        let parameters = PersonLookupInfoRemoteSearchQuery(
            itemID: itemId,
            searchInfo: personLookupInfo
        )
        let request = Paths.getPersonRemoteSearchResults(parameters)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
