//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ProgramsLibrary: PagingLibrary {

    let parent: _TitledLibraryParent
    let section: ProgramSection

    init(section: ProgramSection) {
        self.parent = _TitledLibraryParent(
            displayTitle: section.displayTitle,
            libraryID: "programs-\(section.rawValue)"
        )
        self.section = section
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.fields = [.channelInfo]
        parameters.hasAired = false
        parameters.limit = pageState.pageSize
        parameters.userID = pageState.userSession.user.id

        parameters.isKids = section == .kids
        parameters.isMovie = section == .movies
        parameters.isNews = section == .news
        parameters.isSeries = section == .series
        parameters.isSports = section == .sports

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
