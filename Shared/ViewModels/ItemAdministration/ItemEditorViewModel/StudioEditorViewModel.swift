//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class StudioEditorViewModel: ItemEditorViewModel<NameGuidPair> {

    // MARK: - Populate the Trie

    override func populateTrie() {
        let elements = elements
            .compacted(using: \.name)
            .reduce(into: [String: NameGuidPair]()) { result, element in
                result[element.name!] = element
            }

        trie.insert(contentsOf: elements)
    }

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

    // MARK: - Reorder Tag(s)

    override func reorderComponents(_ studios: [NameGuidPair]) async throws {
        var updatedItem = item
        updatedItem.studios = studios
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
}
