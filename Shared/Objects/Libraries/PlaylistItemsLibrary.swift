//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

struct PlaylistItemsLibrary: BaseItemKindLibrary {

    let libraryItemTypes: [BaseItemKind] = BaseItemKind.supportedCases
        .appending(.episode)
    let parent: TitledLibraryParent

    private let playlistID: String?

    init(playlist: BaseItemDto) {
        self.playlistID = playlist.id
        self.parent = .init(
            displayTitle: L10n.items,
            id: "playlist-items-\(playlist.id ?? "unknown")"
        )
    }

    func retrievePage(
        environment: Empty,
        pageState: LibraryPageState
    ) async throws -> [BaseItemDto] {
        guard let playlistID else {
            throw ErrorMessage(L10n.unknownError)
        }

        var parameters = Paths.GetPlaylistItemsParameters()
        parameters.enableUserData = true
        parameters.fields = .MinimumFields
        parameters.limit = pageState.pageSize
        parameters.startIndex = pageState.pageOffset
        parameters.userID = pageState.userSession.user.id

        let request = Paths.getPlaylistItems(
            playlistID: playlistID,
            parameters: parameters
        )
        let response = try await pageState.userSession.client.send(request)

        return response.value.items ?? []
    }
}
