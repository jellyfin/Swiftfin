//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct PeopleComponentEditor: ItemComponentEditor {

    let description: String = L10n.peopleDescription
    let displayTitle: String = L10n.people
    let supportsPeopleFields: Bool = true

    func elements(in item: BaseItemDto) -> [BaseItemPerson] {
        item.people ?? []
    }

    func id(for element: BaseItemPerson) -> String? {
        element.id
    }

    func name(for element: BaseItemPerson) -> String {
        element.name ?? L10n.unknown
    }

    func makeElement(input: ItemComponentEditorInput) -> BaseItemPerson {
        let role = input.personRole.isEmpty ?
            (input.personKind == .unknown ? nil : input.personKind.rawValue) :
            input.personRole

        return BaseItemPerson(
            id: input.id,
            name: input.name,
            role: role,
            type: input.personKind
        )
    }

    func adding(_ people: [BaseItemPerson], to item: BaseItemDto) -> BaseItemDto {
        var item = item
        if item.people == nil {
            item.people = []
        }
        item.people?.append(contentsOf: people)
        return item
    }

    func removing(_ people: [BaseItemPerson], from item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.people?.removeAll { people.contains($0) }
        return item
    }

    func reordering(_ people: [BaseItemPerson], in item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.people = people
        return item
    }

    func search(_ searchTerm: String, userSession: UserSession) async throws -> [BaseItemPerson] {
        let parameters = Paths.GetPersonsParameters(searchTerm: searchTerm.isEmpty ? nil : searchTerm)
        let request = Paths.getPersons(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items?.map { person in
            BaseItemPerson(id: person.id, name: person.name)
        } ?? []
    }
}
