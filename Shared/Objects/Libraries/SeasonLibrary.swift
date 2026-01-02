//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI

typealias PagingSeasonViewModel = PagingLibraryViewModel<EpisodeLibrary>

@MainActor
struct SeasonViewModelLibrary: PagingLibrary {

    let parent: BaseItemDto

    init(series: BaseItemDto) {
        self.parent = series
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [PagingSeasonViewModel] {
        try await SeasonLibrary(series: parent)
            .retrievePage(
                environment: environment,
                pageState: pageState
            )
            .map { PagingLibraryViewModel(library: EpisodeLibrary(season: $0)) }
    }
}

struct SeasonLibrary: PagingLibrary {

    let parent: BaseItemDto

    init(series: BaseItemDto) {
        self.parent = series
    }

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

        let request = Paths.getSeasons(
            seriesID: seriesID,
            parameters: parameters
        )
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
