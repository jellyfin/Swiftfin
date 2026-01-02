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

final class PeopleEditorViewModel: ItemEditorViewModel<BaseItemPerson> {

    // MARK: - Populate the Trie

    override func populateTrie() {
        let elements = elements
            .compacted(using: \.name)
            .reduce(into: [String: BaseItemPerson]()) { result, element in
                result[element.name!.localizedLowercase] = element
            }

        trie.insert(contentsOf: elements)
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
}
