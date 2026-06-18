//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ProgramsLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.program]
    let parent: TitledLibraryParent
    let section: ProgramSection

    init(section: ProgramSection) {
        self.parent = .init(
            displayTitle: section.displayTitle,
            id: "programs-\(section.rawValue)"
        )
        self.section = section
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.fields = .MinimumFields.appending(.channelInfo)
        parameters.hasAired = false
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
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
