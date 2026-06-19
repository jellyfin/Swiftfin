//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct StudioComponentEditor: ItemComponentEditor {

    let description: String = L10n.studiosDescription
    let displayTitle: String = L10n.studios

    func elements(in item: BaseItemDto) -> [NameIDPair] {
        item.studios ?? []
    }

    func id(for element: NameIDPair) -> String? {
        element.id
    }

    func name(for element: NameIDPair) -> String {
        element.name ?? L10n.unknown
    }

    func makeElement(input: ItemComponentEditorInput) -> NameIDPair {
        NameIDPair(id: input.id, name: input.name)
    }

    func adding(_ studios: [NameIDPair], to item: BaseItemDto) -> BaseItemDto {
        var item = item
        if item.studios == nil {
            item.studios = []
        }
        item.studios?.append(contentsOf: studios)
        return item
    }

    func removing(_ studios: [NameIDPair], from item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.studios?.removeAll { studios.contains($0) }
        return item
    }

    func reordering(_ studios: [NameIDPair], in item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.studios = studios
        return item
    }

    func search(_ searchTerm: String, userSession: UserSession) async throws -> [NameIDPair] {
        let parameters = Paths.GetStudiosParameters(searchTerm: searchTerm.isEmpty ? nil : searchTerm)
        let request = Paths.getStudios(parameters: parameters)
        let response = try await userSession.client.send(request)

        return response.value.items?.map { studio in
            NameIDPair(id: studio.id, name: studio.name)
        } ?? []
    }
}
