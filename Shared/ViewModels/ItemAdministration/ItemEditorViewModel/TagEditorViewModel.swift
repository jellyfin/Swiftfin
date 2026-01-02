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

final class TagEditorViewModel: ItemEditorViewModel<String> {

    // MARK: - Populate the Trie

    override func populateTrie() {
        trie.insert(contentsOf: elements.keyed(using: \.localizedLowercase))
    }

    // MARK: - Add Tag(s)

    override func addComponents(_ tags: [String]) async throws {
        var updatedItem = item
        if updatedItem.tags == nil {
            updatedItem.tags = []
        }
        updatedItem.tags?.append(contentsOf: tags)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove Tag(s)

    override func removeComponents(_ tags: [String]) async throws {
        var updatedItem = item
        updatedItem.tags?.removeAll { tags.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Reorder Tag(s)

    override func reorderComponents(_ tags: [String]) async throws {
        var updatedItem = item
        updatedItem.tags = tags
        try await updateItem(updatedItem)
    }

    // MARK: - Fetch All Possible Tags

    override func fetchElements() async throws -> [String] {
        let parameters = Paths.GetQueryFiltersLegacyParameters(userID: userSession.user.id)
        let request = Paths.getQueryFiltersLegacy(parameters: parameters)
        guard let response = try? await userSession.client.send(request) else { return [] }

        return response.value.tags ?? []
    }
}
