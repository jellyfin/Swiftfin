//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct TagComponentEditor: ItemComponentEditor {

    let description: String = L10n.tagsDescription
    let displayTitle: String = L10n.tags

    private let trie: Trie<String, String> = .init()

    func elements(in item: BaseItemDto) -> [String] {
        item.tags ?? []
    }

    func name(for element: String) -> String {
        element
    }

    func makeElement(input: ItemComponentEditorInput) -> String {
        input.name
    }

    func adding(_ tags: [String], to item: BaseItemDto) -> BaseItemDto {
        var item = item
        if item.tags == nil {
            item.tags = []
        }
        item.tags?.append(contentsOf: tags)
        return item
    }

    func removing(_ tags: [String], from item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.tags?.removeAll { tags.contains($0) }
        return item
    }

    func reordering(_ tags: [String], in item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.tags = tags
        return item
    }

    func didAdd(_ tags: [String]) {
        trie.insert(contentsOf: tags.keyed(using: \.localizedLowercase))
    }

    func search(_ searchTerm: String, userSession: UserSession) async throws -> [String] {
        if trie.isEmpty {
            let parameters = Paths.GetQueryFiltersLegacyParameters(userID: userSession.user.id)
            let request = Paths.getQueryFiltersLegacy(parameters: parameters)
            let response = try await userSession.client.send(request)
            trie.insert(contentsOf: (response.value.tags ?? []).keyed(using: \.localizedLowercase))
        }

        return trie.search(prefix: searchTerm.localizedLowercase)
    }
}
