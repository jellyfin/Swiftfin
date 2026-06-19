//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct GenreComponentEditor: ItemComponentEditor {

    let description: String = L10n.genresDescription
    let displayTitle: String = L10n.genres

    func elements(in item: BaseItemDto) -> [String] {
        item.genres ?? []
    }

    func name(for element: String) -> String {
        element
    }

    func makeElement(input: ItemComponentEditorInput) -> String {
        input.name
    }

    func adding(_ genres: [String], to item: BaseItemDto) -> BaseItemDto {
        var item = item
        if item.genres == nil {
            item.genres = []
        }
        item.genres?.append(contentsOf: genres)
        return item
    }

    func removing(_ genres: [String], from item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.genres?.removeAll { genres.contains($0) }
        return item
    }

    func reordering(_ genres: [String], in item: BaseItemDto) -> BaseItemDto {
        var item = item
        item.genres = genres
        return item
    }

    func search(_ searchTerm: String, state: ItemComponentEditorState) async throws -> [String] {
        let parameters = Paths.GetGenresParameters(searchTerm: searchTerm.isEmpty ? nil : searchTerm)
        let request = Paths.getGenres(parameters: parameters)
        let response = try await state.userSession.client.send(request)

        return response.value.items?.compactMap(\.name) ?? []
    }
}
