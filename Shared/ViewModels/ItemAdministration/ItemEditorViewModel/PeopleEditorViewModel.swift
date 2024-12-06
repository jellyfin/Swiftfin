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

class PeopleEditorViewModel: ItemEditorViewModel<BaseItemPerson> {

    // MARK: - Populate the Trie

    override func populateTrie() {
        for element in self.elements {
            if let name = element.name {
                trie.insert(name)
            }
        }
    }

    // MARK: - Add People(s)

    override func addComponents(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        if updatedItem.people == nil {
            updatedItem.people = []
        }
        updatedItem.people?.append(contentsOf: people)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove People(s)

    override func removeComponents(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        updatedItem.people?.removeAll { people.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Reorder Tag(s)

    override func reorderComponents(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        updatedItem.people = people
        try await updateItem(updatedItem)
    }

    // MARK: - Fetch All Possible People

    override func fetchElements() async throws -> [BaseItemPerson] {
        let request = Paths.getPersons()
        let response = try await userSession.client.send(request)

        if let people = response.value.items {
            return people.map { person in
                BaseItemPerson(id: person.id, name: person.name)
            }
        } else {
            return []
        }
    }

    // MARK: - Search For Matching People

    override func searchElements(_ searchTerm: String) async throws -> [BaseItemPerson] {
        guard !searchTerm.isEmpty else { return [] }

        let matchingItems = Set(trie.search(prefix: searchTerm))

        return elements.filter { matchingItems.contains($0.name!) }
    }
}
