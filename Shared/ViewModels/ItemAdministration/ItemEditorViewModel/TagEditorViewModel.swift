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

    private let trie: Trie<String, String> = .init()

    override func searchElements(_ searchTerm: String) async throws -> [String] {
        if trie.isEmpty {
            let parameters = Paths.GetQueryFiltersLegacyParameters(userID: userSession.user.id)
            let request = Paths.getQueryFiltersLegacy(parameters: parameters)
            let response = try await userSession.client.send(request)
            trie.insert(contentsOf: (response.value.tags ?? []).keyed(using: \.localizedLowercase))
        }

        return trie.search(prefix: searchTerm.localizedLowercase)
    }

    override func addComponents(_ tags: [String]) async throws {
        var updatedItem = item

        if updatedItem.tags == nil {
            updatedItem.tags = []
        }

        updatedItem.tags?.append(contentsOf: tags)

        try await updateItem(updatedItem)

        trie.insert(contentsOf: tags.keyed(using: \.localizedLowercase))
    }

    override func removeComponents(_ tags: [String]) async throws {
        var updatedItem = item
        updatedItem.tags?.removeAll { tags.contains($0) }
        try await updateItem(updatedItem)
    }

    override func reorderComponents(_ tags: [String]) async throws {
        var updatedItem = item
        updatedItem.tags = tags
        try await updateItem(updatedItem)
    }

    override func containsElement(named name: String) -> Bool {
        item.tags?.contains { $0.caseInsensitiveCompare(name) == .orderedSame } ?? false
    }

    override func matchExists(named name: String) -> Bool {
        matches.contains { $0.caseInsensitiveCompare(name) == .orderedSame }
    }
}
