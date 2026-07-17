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
    let parent: BaseItemDto

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [PagingLibraryViewModel<EpisodeLibrary>] {
        if parent.type == .season {
            return [PagingLibraryViewModel(library: EpisodeLibrary(season: parent))]
        }

        return try await SeasonLibrary(parent: parent)
            .retrievePage(
                environment: environment,
                pageState: pageState
            )
            .map { PagingLibraryViewModel(library: EpisodeLibrary(season: $0)) }
    }
}

struct SeasonLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.season]
    let parent: BaseItemDto

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard let seriesID = parent.id else {
            throw ErrorMessage(L10n.unknownError)
        }

        var parameters = Paths.GetSeasonsParameters()
        parameters.isMissing = Defaults[.Customization.shouldShowMissingSeasons] ? nil : false
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getSeasons(seriesID: seriesID, parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
