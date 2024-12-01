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

class GenreEditorViewModel: ItemEditorViewModel<String> {

    // MARK: - Add Details

    override func addComponents(_ genres: [String]) async throws {
        var updatedItem = item
        if updatedItem.genres == nil {
            updatedItem.genres = []
        }
        updatedItem.genres?.append(contentsOf: genres)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove Details

    override func removeComponents(_ genres: [String]) async throws {
        var updatedItem = item
        updatedItem.genres?.removeAll { genres.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Validate Details

    override func searchComponent(_ genre: String) async throws -> [String] {
        let parameters = Paths.GetGenresParameters(searchTerm: genre)
        let request = Paths.getGenres(parameters: parameters)
        let response = try await userSession.client.send(request)

        // Return a full list of Genres from the searchTerm
        if let genres = response.value.items {
            return genres.compactMap(\.name).compactMap { $0 }
        } else {
            return []
        }
    }
}
