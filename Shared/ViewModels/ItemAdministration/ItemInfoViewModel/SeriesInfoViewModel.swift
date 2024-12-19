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

class SeriesInfoViewModel: ItemInfoViewModel<SeriesInfo> {

    // MARK: - Return Matching Series

    override func searchItem(_ seriesInfo: SeriesInfo) async throws -> [RemoteSearchResult] {
        guard let itemId = item.id, item.type == .series else {
            return []
        }

        let parameters = SeriesInfoRemoteSearchQuery(
            itemID: itemId,
            searchInfo: seriesInfo
        )
        let request = Paths.getSeriesRemoteSearchResults(parameters)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
