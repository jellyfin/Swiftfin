//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct ChannelProgramsLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = [.program]
    let parent: TitledLibraryParent

    private let channelID: String?

    init(channel: BaseItemDto) {
        self.channelID = channel.id
        self.parent = .init(
            displayTitle: channel.displayTitle,
            id: "channel-programs-\(channel.id ?? "unknown")"
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        var parameters = Paths.GetLiveTvProgramsParameters()
        parameters.channelIDs = [channelID].compactMap(\.self)
        parameters.fields = .MinimumFields.appending(.channelInfo)
        parameters.limit = pageState.pageSize
        parameters.minEndDate = .now
        parameters.sortBy = [.startDate]
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getLiveTvPrograms(parameters: parameters)
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
