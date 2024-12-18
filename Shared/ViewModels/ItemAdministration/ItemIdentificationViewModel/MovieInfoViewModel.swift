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

class MovieInfoViewModel: ItemInfoViewModel<MovieInfo> {

    // MARK: - Return Matching Movies

    override func searchItem(_ movieInfo: MovieInfo) async throws -> [RemoteSearchResult] {
        guard let itemId = item.id, item.type == .movie else {
            return []
        }

        let parameters = MovieInfoRemoteSearchQuery(
            itemID: itemId,
            searchInfo: movieInfo
        )
        let request = Paths.getMovieRemoteSearchResults(parameters)
        let response = try await userSession.client.send(request)

        return response.value
    }
}
