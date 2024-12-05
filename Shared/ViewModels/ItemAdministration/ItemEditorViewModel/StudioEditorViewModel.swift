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

class StudioEditorViewModel: ItemEditorViewModel<NameGuidPair> {

    // MARK: - Add Studio(s)

    override func addComponents(_ studios: [NameGuidPair]) async throws {
        var updatedItem = item
        if updatedItem.studios == nil {
            updatedItem.studios = []
        }
        updatedItem.studios?.append(contentsOf: studios)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove Studio(s)

    override func removeComponents(_ studios: [NameGuidPair]) async throws {
        var updatedItem = item
        updatedItem.studios?.removeAll { studios.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Fetch All Possible Studios

    override func fetchElements() async throws -> [NameGuidPair] {
        let request = Paths.getStudios()
        let response = try await userSession.client.send(request)

        if let studios = response.value.items {
            return studios.map { studio in
                NameGuidPair(id: studio.id, name: studio.name)
            }
        } else {
            return []
        }
    }

    // MARK: - Get Studio Matches

    override func fetchMatches(_ searchTerm: String) async throws -> [NameGuidPair] {
        guard !searchTerm.isEmpty else {
            return []
        }

        return self.elements.compactMap {
            guard let name = $0.name,
                  name.range(of: searchTerm, options: .caseInsensitive) != nil
            else {
                return nil
            }
            return NameGuidPair(id: $0.id, name: name)
        }
    }
}
