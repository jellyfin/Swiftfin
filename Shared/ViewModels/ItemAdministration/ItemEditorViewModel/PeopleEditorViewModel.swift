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

    // MARK: - Search People

    override func searchElements(_ searchTerm: String) async throws -> [BaseItemPerson] {
        let parameters = Paths.GetPersonsParameters(searchTerm: searchTerm.isEmpty ? nil : searchTerm)
        let request = Paths.getPersons(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items?.map { person in
            BaseItemPerson(id: person.id, name: person.name)
        } ?? []
    }

    // MARK: - Add People

    override func addComponents(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        if updatedItem.people == nil {
            updatedItem.people = []
        }
        updatedItem.people?.append(contentsOf: people)
        try await updateItem(updatedItem)
    }

    // MARK: - Remove People

    override func removeComponents(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        updatedItem.people?.removeAll { people.contains($0) }
        try await updateItem(updatedItem)
    }

    // MARK: - Reorder People

    override func reorderComponents(_ people: [BaseItemPerson]) async throws {
        var updatedItem = item
        updatedItem.people = people
        try await updateItem(updatedItem)
    }

    // MARK: - Contains Element

    override func containsElement(named name: String) -> Bool {
        item.people?.contains { $0.name?.caseInsensitiveCompare(name) == .orderedSame } ?? false
    }

    // MARK: - Match Exists

    override func matchExists(named name: String) -> Bool {
        matches.contains { $0.name?.caseInsensitiveCompare(name) == .orderedSame }
    }
}
