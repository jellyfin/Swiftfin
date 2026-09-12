//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

struct SeasonViewModelLibrary: PagingLibrary {

    let hasNextPage = false
    @StoredItem
    var parent: BaseItemDto

    typealias Element = PagingLibraryViewModel<EpisodeLibrary>

    func retrievePage(environment: Empty, pageState: LibraryPageState) async throws -> [ItemPatch] {
        if parent.type == .season {
            return try [ItemPatch(value: parent)]
        }
        return try await SeasonLibrary(parent: parent).retrievePage(environment: environment, pageState: pageState)
    }

    func materialize(_ page: [ItemPatch], pageState: LibraryPageState) throws -> [Element] {
        try SeasonLibrary(parent: parent).materialize(page, pageState: pageState).map {
            PagingLibraryViewModel(library: EpisodeLibrary(season: $0.snapshot), userSession: pageState.userSession)
        }
    }
}

struct SeasonLibrary: BaseItemKindLibrary {

    let hasNextPage = false

    let libraryItemTypes: [BaseItemKind] = [.season]
    @StoredItem
    var parent: BaseItemDto

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [ItemPatch] {
        guard let seriesID = parent.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        var parameters = Paths.GetSeasonsParameters()
        parameters.isMissing = Defaults[.Customization.shouldShowMissingSeasons] ? nil : false
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getSeasons(seriesID: seriesID, parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return try pageState.items(from: response)
    }
}
