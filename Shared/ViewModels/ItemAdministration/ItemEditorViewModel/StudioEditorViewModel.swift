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

    // MARK: - Search Studios

    override func searchElements(_ searchTerm: String) async throws -> [NameGuidPair] {
        let parameters = Paths.GetStudiosParameters(searchTerm: searchTerm.isEmpty ? nil : searchTerm)
        let request = Paths.getStudios(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items?.map { studio in
            NameGuidPair(id: studio.id, name: studio.name)
        } ?? []
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

    // MARK: - Reorder Studio(s)

    override func reorderComponents(_ studios: [NameGuidPair]) async throws {
        var updatedItem = item
        updatedItem.studios = studios
        try await updateItem(updatedItem)
    }

    // MARK: - Contains Element

    override func containsElement(named name: String) -> Bool {
        item.studios?.contains { $0.name?.caseInsensitiveCompare(name) == .orderedSame } ?? false
    }

    // MARK: - Match Exists

    override func matchExists(named name: String) -> Bool {
        matches.contains { $0.name?.caseInsensitiveCompare(name) == .orderedSame }
    }
}
